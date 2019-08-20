local NUM_SPIKES = 5
local SPIKE_FLIGHT_TIME = 0.22
local SPIKE_START_HEIGHT = 100
local DELAY_BETWEEN_SPIKES = 0.02

if IceSpikes == nil then
	IceSpikes = class({})
end

function IceSpikes:Precache(context)
	PrecacheResource("particle_folder", "particles/ice_spikes", context)
	PrecacheResource("particle_folder", "particles/ice_spikes/charging_particle", context)
end

function IceSpikes:PlayerConnected(player)

end


function IceSpikes:StartIceSpikes(player, modifierElement)
	local caster = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_CHARGING,
		duration = 2.6,
		cooldown = 0.6,
		chargingPhase1Duration = 2.1,
		chargingPhase2Duration = 0.5,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) 
			IceSpikes:ReleaseSpikes(player, modifierElement)
		end,
		thinkPeriod = 2.1,
		thinkFunction = function(player)
			caster:EmitSound("RockOvercharge")
		end,
		slowMovePercentage = 50,
		chargingParticle = "particles/ice_spikes/charging_particle/charging_particle.vpcf"
	}
	Spells:StartCasting(player, spellCastTable)
	caster:EmitSound("RockCharging")
end

function IceSpikes:ReleaseSpikes(player, modifierElement)
	local caster = player:GetAssignedHero()
	
	caster:StopSound("RockCharging")
	caster:StopSound("RockOvercharge")

	local timeElapsed = Spells:TimeElapsedSinceCast(player)
	local phase1 = player.spellCast.chargingPhase1Duration
	local t = math.min(phase1, timeElapsed) / phase1

	local startPos = caster:GetAbsOrigin() + Vector(0, 0, SPIKE_START_HEIGHT)
	local forward = caster:GetForwardVector()
	local right = caster:GetRightVector()

	local distance = Util:Lerp(150, 1500, t)
	local endSpreadPerpendicular = (distance < 350) and 200 or 300
	local endSpreadAlong = distance * 0.2

	local iceDamageFunc = HP:MakeReciprocalApplying(Util:Lerp(25, 150, t))
	local modifierDamageFunc = IceSpikes:MakeModifierElementDamageValue(t, modifierElement)

	local function hitUnit(unit)
		HP:ApplyElement(unit, caster, PSEUDO_ELEMENT_ICE, iceDamageFunc)
		if modifierDamageFunc ~= nil then
			HP:ApplyElement(unit, caster, modifierElement, modifierDamageFunc)
		end
	end

	local function launchSpike(endPos)
		local startToEnd = endPos - startPos
		local startToEndLen = #startToEnd
		Projectile:Create({
			caster = caster,
			start = startPos,
			direction = startToEnd / startToEndLen,
			distance = startToEndLen,
			flightDuration = SPIKE_FLIGHT_TIME,
			collisionRadius = 40,
			destroyDelay = 2.0,
			particleDestroyDelay = 0.2,
			onDeathCallback = function(spike, unitsTouched)
				for _, unit in pairs(unitsTouched) do
					hitUnit(unit)
				end
				IceSpikes:StopParticles(spike)
				IceSpikes:ImpactParticle(spike, modifierElement)
			end,
			createParticleCallback = function(spike)
				return IceSpikes:CreateParticle(spike, modifierElement)
			end
		})
	end

	if timeElapsed < 2.5 then
		local indices = table.createRange(0, NUM_SPIKES)
		Timers:CreateTimer(function()
			local i = table.popRandom(indices)
			if i == nil then
				return nil
			end

			local offsetPerpendicular = right * endSpreadPerpendicular * ((i / (NUM_SPIKES - 1) - 0.5) + RandomFloat(-0.1, 0.1))
			local offsetAlong = forward * endSpreadAlong * RandomFloat(-0.5, 0.5)
			local endPos = startPos + forward * distance + offsetPerpendicular + offsetAlong
			launchSpike(endPos)

			return DELAY_BETWEEN_SPIKES
		end)
	else
		for i = 0, NUM_SPIKES - 1 do
			local offsetPerpendicular = right * endSpreadPerpendicular * (i / (NUM_SPIKES - 1) - 0.5)
			local endPos = startPos + forward * distance + offsetPerpendicular
			launchSpike(endPos)
		end
		caster:AddNewModifier(caster, nil, "modifier_knockdown", { duration = 2.0 })
	end

	local launchWaveParticle = ParticleManager:CreateParticle("particles/rock_throw/rock_launch_wave.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(launchWaveParticle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(launchWaveParticle, 1, Vector(distance, 0, 0))
	ParticleManager:SetParticleControl(launchWaveParticle, 2, Vector(0, caster:GetAnglesAsVector().y, 0))
end

function IceSpikes:MakeModifierElementDamageValue(t, modifierElement)
	local function make(min, max) return HP:MakeReciprocalApplying(Util:Lerp(min, max, t)) end
	local damageValueTable = {
		[ELEMENT_WATER] = 1,
		[ELEMENT_COLD]  = make(1, 30),
		[ELEMENT_LIFE]  = make(35, 225),
		[ELEMENT_DEATH] = make(1, 50)
	}
	return damageValueTable[modifierElement]
end

function IceSpikes:CreateParticle(spike, modifierElement)
	local deathTrail = modifierElement == ELEMENT_DEATH
	local iceTrail = not deathTrail
	local waterTrail = modifierElement == ELEMENT_WATER
	local coldTrail = modifierElement == ELEMENT_COLD
	local spikeRadiusScale = 1
	
	local particle = ParticleManager:CreateParticle("particles/ice_spikes/ice_spike.vpcf", PATTACH_ABSORIGIN_FOLLOW, spike)
	local function to01(x) return x and 1 or 0 end
	ParticleManager:SetParticleControl(particle, 1, Vector(to01(iceTrail), to01(waterTrail), to01(coldTrail)))
	ParticleManager:SetParticleControl(particle, 2, Vector(to01(deathTrail), 0, 0))
	ParticleManager:SetParticleControl(particle, 3, Vector(spikeRadiusScale, 0, 0))

	return particle
end

function IceSpikes:StopParticles(spike)
	ParticleManager:SetParticleControl(spike.particle, 3, Vector(0, 0, 0))
end

function IceSpikes:ImpactParticle(spike, modifierElement)
	RockThrow:ImpactParticle(spike:GetAbsOrigin(), 1)
end