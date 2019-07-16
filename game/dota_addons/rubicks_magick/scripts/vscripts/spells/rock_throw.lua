require("libraries/timers")

if RockThrow == nil then
	RockThrow = class({})
end

function RockThrow:Precache(context)
	LinkLuaModifier("modifier_bursted_body_invis", "modifiers/modifier_bursted_body_invis.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/rock_throw", context)
	PrecacheResource("particle_folder", "particles/rock_throw/charging_particle", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/rock_throw.vsndevts", context)
end

function RockThrow:PlayerConnected(player)

end

function RockThrow:Init()
	RockThrow.rockDummiesList = {}
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(RockThrow, "OnRockThink"), "RockThink", ROCK_THINK_PERIOD)
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(RockThrow, "OnNPCSpawned"), self)
end

function RockThrow:StartRockThrow(player, pickedElements)
	local caster = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_CHARGING,
		duration = 2.6,
		chargingPhase1Duration = 2.1,
		chargingPhase2Duration = 0.5,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) RockThrow:ReleaseRock(player) end,
		thinkPeriod = 2.1,
		thinkFunction = function(player)
			caster:EmitSound("RockOvercharge")
		end,
		slowMovePercentage = 50,
		chargingParticle = "particles/rock_throw/charging_particle/charging_particle.vpcf",
		rockThrow_PickedElements = pickedElements
	}
	Spells:StartCasting(player, spellCastTable)
	caster:EmitSound("RockCharging")
end

ROCK_FLY_TIME = 0.12
ROCK_START_HEIGHT = 100
ROCK_FALL_G_CONST = 2 * ROCK_START_HEIGHT / (ROCK_FLY_TIME * ROCK_FLY_TIME)
ROCK_THINK_PERIOD = 0.018

function RockThrow:ReleaseRock(player)
	local caster = player:GetAssignedHero()
	caster:StopSound("RockCharging")
	caster:StopSound("RockOvercharge")
	caster:EmitSound("RockRelease")

	local pickedElements = player.spellCast.rockThrow_PickedElements

	local earthCount = table.count(pickedElements, ELEMENT_EARTH)
	local rockSize = earthCount
	
	local timeElapsed = Spells:TimeElapsedSinceCast(player)

	local phase1 = player.spellCast.chargingPhase1Duration
	local timeFactor = math.min(phase1, timeElapsed) / phase1
	local damageFactor = timeFactor
	local radiusFactor = 0.4 + 0.6 * timeFactor

	local minRockDamage = ({ 30, 40, 50 })[rockSize]
	local maxRockDamage = ({ 125, 300, 600 })[rockSize]
	local rockDamage = Util:Lerp(minRockDamage, maxRockDamage, timeFactor)

	local minDistance = 45
	local maxDistance = ({ 1800, 1500, 1200 })[rockSize]
	local distance = Util:Lerp(minDistance, maxDistance, timeFactor)

	local radiuses = GetScaledRadiuses(radiusFactor)

	if timeElapsed >= 2.4 then
		rockDamage = ({ 135, 330, 650 })[rockSize]
	end

	local rockImpactTable = {
		[ELEMENT_EARTH] = {			
			[ELEMENT_EARTH] = {
				[ELEMENT_LIFE]  = function(pos) OmniPulses:OmniLifePulse(caster, pos, false, pickedElements, radiusFactor, damageFactor * 2) end,
				[ELEMENT_DEATH] = function(pos) OmniPulses:OmniDeathPulse(caster, pos, false, pickedElements, radiusFactor, damageFactor) end,
				[ELEMENT_FIRE]  = function(pos) OmniElementSprays:OmniFireSpray(caster, pos, radiuses[1], false, 100 * damageFactor) end,
				[ELEMENT_COLD]  = function(pos) OmniElementSprays:OmniColdSpray(caster, pos, radiuses[1], false, 55 * damageFactor) end,
				[ELEMENT_WATER] = function(pos) OmniElementSprays:OmniWaterSpray(caster, pos, radiuses[1], false, false) end
			},
			[ELEMENT_LIFE]  = function(pos) OmniPulses:OmniLifePulse(caster, pos, false, pickedElements, radiusFactor, damageFactor * 2) end,
			[ELEMENT_DEATH] = function(pos) OmniPulses:OmniDeathPulse(caster, pos, false, pickedElements, radiusFactor, damageFactor * 1.2) end,
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE]  = function(pos) OmniElementSprays:OmniSteamSpray(caster, pos, radiuses[1], false, 170 * damageFactor, false) end,
				[ELEMENT_WATER] = function(pos) OmniElementSprays:OmniWaterSpray(caster, pos, radiuses[2], false, false) end,
				[EMPTY]         = function(pos) OmniElementSprays:OmniWaterSpray(caster, pos, radiuses[1], false, false) end,
				[ELEMENT_COLD]  = function(pos, unitsTouched)
					for _, unit in pairs(unitsTouched) do
						if unit ~= caster then
							Spells:ApplyElementDamage(unit, caster, ELEMENT_COLD,  150 * damageFactor, false, 1.0, true)
							Spells:ApplyElementDamage(unit, caster, ELEMENT_WATER, 150 * damageFactor, false, 1.0)
						end
					end
				end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE]  = function(pos) OmniElementSprays:OmniFireSpray(caster, pos, radiuses[2], false, 212 * damageFactor) end,
				[EMPTY]         = function(pos) OmniElementSprays:OmniFireSpray(caster, pos, radiuses[1], false, 100 * damageFactor) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD]  = function(pos) OmniElementSprays:OmniColdSpray(caster, pos, radiuses[2], false, 113 * damageFactor) end,
				[EMPTY]         = function(pos) OmniElementSprays:OmniColdSpray(caster, pos, radiuses[1], false, 55 * damageFactor) end
			}
		}
	}
	local onImpactFunction = table.serialRetrieve(rockImpactTable, pickedElements)

	local forward = caster:GetForwardVector():Normalized()
	local startOrigin = caster:GetAbsOrigin() + Vector(0, 0, ROCK_START_HEIGHT)
	local rockDummy = Util:CreateDummy(startOrigin, caster)
	rockDummy.caster = caster
	rockDummy.time = 0.0
	rockDummy.startZ = startOrigin.z
	rockDummy.moveStep = forward * (distance * (ROCK_THINK_PERIOD / ROCK_FLY_TIME))
	rockDummy.moveStep.z = 0
	rockDummy.rockSize = rockSize
	rockDummy.collisionRadius = rockSize * 16 + 18
	rockDummy.rockDamage = rockDamage
	rockDummy.onImpactFunction = onImpactFunction
	rockDummy.particle = RockThrow:CreateRockParticle(rockDummy, pickedElements)
	table.insert(RockThrow.rockDummiesList, rockDummy)

	local launchWaveParticle = ParticleManager:CreateParticle("particles/rock_throw/rock_launch_wave.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(launchWaveParticle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(launchWaveParticle, 1, Vector(distance, 0, 0))
	ParticleManager:SetParticleControl(launchWaveParticle, 2, Vector(0, caster:GetAnglesAsVector().y, 0))

	if timeElapsed >= 2.5 then
		rockDamage = ({ 135, 330, 650 })[rockSize]
		caster:AddNewModifier(caster, nil, "modifier_knockdown", { duration = 2.0 })
	end
end

function RockThrow:CreateRockParticle(rockDummy, pickedElements)
	local waterTrail = 0
	local fireTrail = 0
	local coldTrail = 0
	local deathTrail = 0
	local lifeTrail = 0
	local steamTrail = 0
	local ice = 0

	local rockSize = 0
	local earthOnly = 1
	for i, element in pairs(pickedElements) do
		if element == ELEMENT_EARTH then 
			rockSize = rockSize + 1
		else
			earthOnly = 0
			if     element == ELEMENT_WATER then waterTrail = 1
			elseif element == ELEMENT_FIRE  then fireTrail = 1
			elseif element == ELEMENT_COLD  then coldTrail = 1
			elseif element == ELEMENT_DEATH then deathTrail = 1
			elseif element == ELEMENT_LIFE  then lifeTrail = 1
			end
		end
	end
	if fireTrail == 1 and waterTrail == 1 then
		fireTrail = 0
		waterTrail = 0
		steamTrail = 1
	end
	if waterTrail == 1 and coldTrail == 1 then
		waterTrail = 0
		coldTrail = 0
		ice = 1
	end

	local particle = ParticleManager:CreateParticle("particles/rock_throw/rock.vpcf", PATTACH_ABSORIGIN_FOLLOW, rockDummy)
	ParticleManager:SetParticleControl(particle, 1, Vector(rockSize, earthOnly, ice))
	ParticleManager:SetParticleControl(particle, 2, Vector(waterTrail, fireTrail, coldTrail))
	ParticleManager:SetParticleControl(particle, 3, Vector(deathTrail, lifeTrail, steamTrail))
	return particle
end

function RockThrow:OnRockThink()
	for _, rockDummy in pairs(RockThrow.rockDummiesList) do
		RockThrow:RockDummyThink(rockDummy)
	end
	return ROCK_THINK_PERIOD
end

function RockThrow:RockDummyThink(rockDummy)
	local origin = rockDummy:GetAbsOrigin()
	if origin.z <= GetGroundHeight(origin, rockDummy) then
		RockThrow:ImpactRock(rockDummy, {})
		return
	end
	
	local time = rockDummy.time
	rockDummy.time = time + ROCK_THINK_PERIOD
	if time == 0 then
		return
	end

	local oldOrigin = origin
	origin = origin + rockDummy.moveStep
	origin.z = rockDummy.startZ - ROCK_FALL_G_CONST * time * time / 2
	rockDummy:SetAbsOrigin(origin)
	
	local caster = rockDummy.caster
	local trees = GridNav:GetAllTreesAroundPoint(origin, rockDummy.collisionRadius, true)
	if next(trees) ~= nil then
		RockThrow:ImpactRock(rockDummy, {})
		return
	end

	local damage = rockDummy.rockDamage
	local unitsTouched = Util:FindUnitsInLine(oldOrigin, origin, rockDummy.collisionRadius, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	for _, unit in pairs(unitsTouched) do
		if unit ~= rockDummy and unit ~= caster then
			Util:EmitSoundOnLocation(origin, "RockTouch", caster)
			local powerfulEnoughForBurst = rockDummy.rockSize == 3 and damage >= 450
			if unit:IsFrozen() then
				if powerfulEnoughForBurst then
					unit:RemoveModifierByName("modifier_frozen")
					RockThrow:MakeBurstedBodyInvisible(unit)
					Spells:ApplyElementDamage(unit, caster, ELEMENT_EARTH, damage * 10, false, 0.0, true)
					RockThrow:BurstFrozenParticle(origin)
					RockThrow:PlayBurstSound(origin, caster, true)
				else
					RockThrow:ImpactRock(rockDummy, unitsTouched)
					break
				end
			else
				local damageAfterShields = Spells:GetDamageAfterShields(unit, damage, ELEMENT_EARTH)
				if powerfulEnoughForBurst and unit:GetHealth() - damageAfterShields <= 0 then
					RockThrow:MakeBurstedBodyInvisible(unit)
					Spells:ApplyElementDamage(unit, caster, ELEMENT_EARTH, damage, false)
					RockThrow:BurstBloodParticle(origin)
					RockThrow:PlayBurstSound(origin, caster, false)
				else
					RockThrow:ImpactRock(rockDummy, unitsTouched)
					break
				end
			end
		end
	end
end

function RockThrow:ImpactRock(rockDummy, unitsTouched)
	table.removeItem(RockThrow.rockDummiesList, rockDummy)

	local origin = GetGroundPosition(rockDummy:GetAbsOrigin(), rockDummy) + Vector(0, 0, 40)
	if rockDummy.onImpactFunction ~= nil then
		rockDummy.onImpactFunction(origin, unitsTouched)
	end
	if next(unitsTouched) == nil then
		Spells:ApplyElementDamageAoE(origin, rockDummy.collisionRadius, rockDummy.caster, ELEMENT_EARTH, rockDummy.rockDamage, true)
	else
		for _, unit in pairs(unitsTouched) do
			if unit ~= rockDummy.caster then
				Spells:ApplyElementDamage(unit, rockDummy.caster, ELEMENT_EARTH, rockDummy.rockDamage)
			end
		end
	end
	
	Util:EmitSoundOnLocation(origin, "RockImpact", rockDummy.caster)
	Util:EmitSoundOnLocation(origin, "RockTouch", rockDummy.caster)
	
	ParticleManager:SetParticleControl(rockDummy.particle, 0, origin)
	Timers:CreateTimer(0.05, function()
		ParticleManager:SetParticleControl(rockDummy.particle, 1, Vector(rockDummy.rockSize, 0, 0))
		ParticleManager:SetParticleControl(rockDummy.particle, 2, Vector(0, 0, 0))
		ParticleManager:SetParticleControl(rockDummy.particle, 3, Vector(0, 0, 0))
	end)

	RockThrow:ImpactParticle(origin, rockDummy.rockSize)
	Timers:CreateTimer(0.2, function() ParticleManager:DestroyParticle(rockDummy.particle, false) end)
	Timers:CreateTimer(2.0, function() rockDummy:Destroy() end)
end

function RockThrow:PlayBurstSound(position, caster, frozen)
	Util:EmitSoundOnLocation(position, "RockBurst1", caster)
	Util:EmitSoundOnLocation(position, "RockBurst2", caster)
	Util:EmitSoundOnLocation(position, "RockBurst3", caster)
	Util:EmitSoundOnLocation(position, "RockBurst4", caster)
	if frozen then
		Util:EmitSoundOnLocation(position, "RockBurstFrozen", caster)
	end
end

function RockThrow:ImpactParticle(position, shardsSize)
	local impactParticle = ParticleManager:CreateParticle("particles/rock_throw/rock_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(impactParticle, 0, position)
	ParticleManager:SetParticleControl(impactParticle, 1, Vector(shardsSize, 0, 0))
end

function RockThrow:BurstBloodParticle(position)
	local burstMeatParticle = ParticleManager:CreateParticle("particles/rock_throw/rock_burst_blood.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(burstMeatParticle, 0, position)
end

function RockThrow:BurstFrozenParticle(position)
	local burstMeatParticle = ParticleManager:CreateParticle("particles/rock_throw/rock_burst_frozen.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(burstMeatParticle, 0, position)
end

function RockThrow:MakeBurstedBodyInvisible(unit)
	unit:AddNewModifier(nil, nil, "modifier_bursted_body_invis", {})
end

function RockThrow:OnNPCSpawned(keys)
	local unit = EntIndexToHScript(keys.entindex)
	unit:RemoveModifierByName("modifier_bursted_body_invis")
end