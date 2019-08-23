require("libraries/timers")

local ROCK_FLIGHT_TIME = 0.22
local ROCK_START_HEIGHT = 100

if RockThrow == nil then
	RockThrow = class({})
end

function RockThrow:Precache(context)
	LinkLuaModifier("modifier_bursted_body_invis", "modifiers/modifier_bursted_body_invis.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/rock_throw", context)
	PrecacheResource("particle_folder", "particles/rock_throw/charging_particle", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/rock_throw.vsndevts", context)

	PrecacheResource("soundfile", "sounds/weapons/hero/windrunner/focus_fire.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/tiny/preattack02.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/tiny/tiny_attack.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/tiny/tiny_attack2.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/tiny/tiny_attack3.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/tiny/tiny_attack4.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/earthshaker/fissure.vsnd", context)
	PrecacheResource("soundfile", "sounds/physics/deaths/common/body_impact_heavy_01.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/pudge/dismember_blood1.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/pudge/dismember_blood2.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/pudge/dismember_blood3.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/monkey_king/stike_impact02.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/tusk/punch_target.vsnd", context)
	PrecacheResource("soundfile", "sounds/physics/damage/building/radiant_tower_destruction_03.vsnd", context)
end

function RockThrow:PlayerConnected(player)

end

function RockThrow:Init()
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(RockThrow, "OnNPCSpawned"), self)
end

function RockThrow:StartRockThrow(player, pickedElements)
	local caster = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_CHARGING,
		duration = 2.6,
		cooldown = 0.6,
		chargingPhase1Duration = 2.1,
		chargingPhase2Duration = 0.5,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) 
			RockThrow:ReleaseRock(player) 
		end,
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
	local t = math.min(phase1, timeElapsed) / phase1
	local damageFactor = t
	local radiusFactor = 0.4 + 0.6 * t

	local minRockDamage = ({ 30, 40, 50 })[rockSize]
	local maxRockDamage = ({ 125, 300, 600 })[rockSize]
	local rockDamage = Util:Lerp(minRockDamage, maxRockDamage, t)

	local minDistance = 45
	local maxDistance = ({ 1800, 1500, 1200 })[rockSize]
	local distance = Util:Lerp(minDistance, maxDistance, t)

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
							HP:ApplyElement(unit, caster, PSEUDO_ELEMENT_ICE, 300 * damageFactor)
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

	if timeElapsed >= 2.5 then
		caster:AddNewModifier(caster, nil, "modifier_knockdown", { duration = 2.0 })
	end

	local rock = Projectile:Create({
		caster = caster,
		start = caster:GetAbsOrigin() + Vector(0, 0, ROCK_START_HEIGHT),
		direction = caster:GetForwardVector(),
		distance = distance,
		flightDuration = ROCK_FLIGHT_TIME,
		collisionRadius = rockSize * 16 + 18,
		destroyDelay = 2.0,
		particleDestroyDelay = 0.2,
		onUnitHitCallback = function(rock, unit) 
			return RockThrow:OnUnitHit(rock, unit) 
		end,
		onDeathCallback = function(rock, unitsTouched) 
			RockThrow:OnRockDeath(rock, unitsTouched) 
		end,
		createParticleCallback = function(rock) 
			return RockThrow:CreateRockParticle(rock, pickedElements) 
		end
	})

	rock.rockSize = rockSize
	rock.rockDamage = rockDamage
	rock.onImpactFunction = onImpactFunction

	local launchWaveParticle = ParticleManager:CreateParticle("particles/rock_throw/rock_launch_wave.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(launchWaveParticle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(launchWaveParticle, 1, Vector(distance, 0, 0))
	ParticleManager:SetParticleControl(launchWaveParticle, 2, Vector(0, caster:GetAnglesAsVector().y, 0))
end


function RockThrow:OnUnitHit(rock, unit)
	local origin = rock:GetAbsOrigin()
	local caster = rock.caster
	local damage = rock.rockDamage

	Util:EmitSoundOnLocation(origin, "RockTouch", caster)

	local powerfulEnoughForBurst = rock.rockSize == 3 and damage >= 450
	if unit:IsFrozen() then
		if not powerfulEnoughForBurst then
			return false
		end

		unit:RemoveModifierByName("modifier_frozen")
		RockThrow:MakeBurstedBodyInvisible(unit)
		HP:ApplyElement(unit, caster, ELEMENT_EARTH, damage * 10, true)
		RockThrow:BurstFrozenParticle(origin)
		RockThrow:PlayBurstSound(origin, caster, true)
		return true
	end
	
	local damageAfterShields = HP:GetDamageAfterShields(unit, damage, ELEMENT_EARTH)
	local hasResistance = SelfShield:HasAnyResistanceTo(unit, ELEMENT_EARTH)
	if not powerfulEnoughForBurst or unit:GetHealth() - damageAfterShields > 0 or hasResistance then
		return false
	end

	RockThrow:MakeBurstedBodyInvisible(unit)
	HP:ApplyElement(unit, caster, ELEMENT_EARTH, damage)
	RockThrow:BurstBloodParticle(origin)
	RockThrow:PlayBurstSound(origin, caster, false)
	return true
end

function RockThrow:OnRockDeath(rock, unitsTouched)
	local origin = GetGroundPosition(rock:GetAbsOrigin(), rock) + Vector(0, 0, 40)
	if rock.onImpactFunction ~= nil then
		rock.onImpactFunction(origin, unitsTouched)
	end
	if next(unitsTouched) == nil then
		HP:ApplyElementAoE(origin, rock.collisionRadius, rock.caster, ELEMENT_EARTH, rock.rockDamage, true)
	else
		for _, unit in pairs(unitsTouched) do
			HP:ApplyElement(unit, rock.caster, ELEMENT_EARTH, rock.rockDamage)
		end
	end
	
	Util:EmitSoundOnLocation(origin, "RockImpact", rock.caster)
	Util:EmitSoundOnLocation(origin, "RockTouch", rock.caster)
	
	ParticleManager:SetParticleControl(rock.particle, 0, origin)
	ParticleManager:SetParticleControl(rock.particle, 1, Vector(0, rock.particleCP1.y, rock.particleCP1.z))

	RockThrow:ImpactParticle(origin, rock.rockSize)
end

function RockThrow:CreateRockParticle(rock, pickedElements)
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

	rock.particleCP1 = Vector(rockSize, earthOnly, ice)
	rock.particleCP2 = Vector(waterTrail, fireTrail, coldTrail)
	rock.particleCP3 = Vector(deathTrail, lifeTrail, steamTrail)

	local particle = ParticleManager:CreateParticle("particles/rock_throw/rock.vpcf", PATTACH_ABSORIGIN_FOLLOW, rock)
	ParticleManager:SetParticleControl(particle, 1, rock.particleCP1)
	ParticleManager:SetParticleControl(particle, 2, rock.particleCP2)
	ParticleManager:SetParticleControl(particle, 3, rock.particleCP3)
	return particle
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