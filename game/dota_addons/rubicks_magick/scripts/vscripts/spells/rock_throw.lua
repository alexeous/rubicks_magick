require("libraries/timers")

if RockThrow == nil then
	RockThrow = class({})
end

function RockThrow:Precache(context)
	PrecacheResource("paritcle_folder", "particles/rock_throw", context)
	PrecacheResource("paritcle_folder", "particles/rock_throw/charging_particle", context)
	PrecacheResource("model", "models/particle/meteor.vmdl", context)
end

function RockThrow:PlayerConnected(player)

end

function RockThrow:Init()
	RockThrow.rockDummiesList = {}
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(RockThrow, "OnRockThink"), "RockThink", ROCK_THINK_PERIOD)
end

function RockThrow:StartRockThrow(player, pickedElements)
	local spellCastTable = {
		castType = CAST_TYPE_CHARGING,
		duration = 2.5,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) RockThrow:ReleaseRock(player) end,
		slowMovePercentage = 30,
		chargingParticle = "particles/rock_throw/charging_particle/charging_particle.vpcf",
		rockThrow_PickedElements = pickedElements
	}
	Spells:StartCasting(player, spellCastTable)
end

ROCK_FLY_DISTANCES = { 2000, 1600, 1400 }
ROCK_FLY_TIME = 0.12
ROCK_START_HEIGHT = 100
ROCK_FALL_G_CONST = 2 * ROCK_START_HEIGHT / (ROCK_FLY_TIME * ROCK_FLY_TIME)
ROCK_THINK_PERIOD = 0.018

function RockThrow:ReleaseRock(player)
	local caster = player:GetAssignedHero()
	local pickedElements = player.spellCast.rockThrow_PickedElements

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

	local timeFactor = math.min(2.0, Spells:TimeElapsedSinceCast(player)) / 2.0
	local damageFactor = 0.15 + 0.85 * timeFactor
	local radiusFactor = 0.4 + 0.6 * timeFactor
	local distanceFactor = 0.05 + 0.95 * timeFactor
	local rockDamages = { 125, 300, 600 }
	local rockDamage = rockDamages[rockSize] * damageFactor
	if rockSize == 1 and earthOnly == 1 then
		rockDamage = 135
	end
	local radiuses = GetScaledRadiuses(radiusFactor)

	local rockImpactTable = {
		[ELEMENT_EARTH] = {			
			[ELEMENT_EARTH] = {
				[ELEMENT_LIFE]  = function(pos) OmniPulses:OmniLifePulse(caster, pos, false, {}, radiusFactor, damageFactor * 2) end,
				[ELEMENT_DEATH] = function(pos) OmniPulses:OmniDeathPulse(caster, pos, false, {}, radiusFactor, damageFactor) end,
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
				[ELEMENT_COLD]  = function(pos)
					Spells:ApplyElementDamageAoE(pos, 30, caster, ELEMENT_COLD,  150 * damageFactor, true, false, 1.0)
					Spells:ApplyElementDamageAoE(pos, 30, caster, ELEMENT_WATER, 150 * damageFactor, true, false, 1.0)
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

	local rockRadius = rockSize * 8 + 4
	local distance = ROCK_FLY_DISTANCES[rockSize] * distanceFactor
	local startOrigin = caster:GetAbsOrigin() + Vector(0, 0, ROCK_START_HEIGHT + rockRadius)
	local rockDummy = Util:CreateDummy(startOrigin, caster)
	rockDummy.caster = caster
	rockDummy.time = 0.0
	rockDummy.startZ = startOrigin.z
	rockDummy.moveStep = caster:GetForwardVector():Normalized() * (distance * (ROCK_THINK_PERIOD / ROCK_FLY_TIME))
	rockDummy.moveStep.z = 0
	rockDummy.rockSize = rockSize
	rockDummy.collisionRadius = rockSize * 16 + 18
	rockDummy.rockDamage = rockDamage
	rockDummy.onImpactFunction = onImpactFunction
	local particle = ParticleManager:CreateParticle("particles/rock_throw/rock.vpcf", PATTACH_ABSORIGIN_FOLLOW, rockDummy)
	ParticleManager:SetParticleControl(particle, 1, Vector(rockSize, earthOnly, ice))
	ParticleManager:SetParticleControl(particle, 2, Vector(waterTrail, fireTrail, coldTrail))
	ParticleManager:SetParticleControl(particle, 3, Vector(deathTrail, lifeTrail, steamTrail))
	rockDummy.particle = particle
	table.insert(RockThrow.rockDummiesList, rockDummy)
end

function RockThrow:OnRockThink()
	for _, rockDummy in pairs(RockThrow.rockDummiesList) do
		local origin = rockDummy:GetAbsOrigin()
		if origin.z <= GetGroundHeight(origin, rockDummy) then
			RockThrow:ImpactRock(rockDummy)
		else
			rockDummy.time = rockDummy.time + ROCK_THINK_PERIOD

			local oldOrigin = origin
			origin = origin + rockDummy.moveStep
			origin.z = rockDummy.startZ - ROCK_FALL_G_CONST * rockDummy.time * rockDummy.time / 2
			rockDummy:SetAbsOrigin(origin)
			
			local caster = rockDummy.caster
			local trees = GridNav:GetAllTreesAroundPoint(origin, rockDummy.collisionRadius, true)
			if next(trees) ~= nil then
				RockThrow:ImpactRock(rockDummy)
			else
				local damage = rockDummy.rockDamage
				local unitsTouched = Util:FindUnitsInLine(oldOrigin, origin, rockDummy.collisionRadius, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
				for _, unit in pairs(unitsTouched) do
					if unit ~= rockDummy and unit ~= caster then
						if unit:IsFrozen() then
							if rockDummy.rockSize == 3 and damage >= 450 then
								unit:RemoveModifierByName("modifier_frozen")
								Spells:ApplyElementDamage(unit, caster, ELEMENT_EARTH, damage * 10, false, 0.0, true)
							else
								rockDummy:SetAbsOrigin(unit:GetAbsOrigin())
								RockThrow:ImpactRock(rockDummy)
								break
							end
						else
							local damageAfterShields = Spells:GetDamageAfterShields(unit, damage, ELEMENT_EARTH)
							if rockDummy.rockSize == 3 and unit:GetHealth() - damageAfterShields <= 0 then
								Spells:ApplyElementDamage(unit, caster, ELEMENT_EARTH, damageAfterShields, false)
							else
								rockDummy:SetAbsOrigin(unit:GetAbsOrigin())
								RockThrow:ImpactRock(rockDummy)
								break
							end
						end
					end
				end
			end
		end
	end
	return ROCK_THINK_PERIOD
end

function RockThrow:ImpactRock(rockDummy)
	local index = table.indexOf(RockThrow.rockDummiesList, rockDummy)
	table.remove(RockThrow.rockDummiesList, index)

	local origin = GetGroundPosition(rockDummy:GetAbsOrigin(), rockDummy) + Vector(0, 0, 40)
	if rockDummy.onImpactFunction ~= nil then
		rockDummy.onImpactFunction(origin)
	end
	Spells:ApplyElementDamageAoE(origin, rockDummy.collisionRadius + 20, rockDummy.caster, ELEMENT_EARTH, rockDummy.rockDamage, true, false)
	ParticleManager:SetParticleControl(rockDummy.particle, 0, origin)
	ParticleManager:DestroyParticle(rockDummy.particle, false)
	Timers:CreateTimer(2.0, function() rockDummy:Destroy() end)
end