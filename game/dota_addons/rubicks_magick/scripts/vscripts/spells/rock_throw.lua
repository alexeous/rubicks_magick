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

function RockThrow:StartRockThrow(player, modifierElements)
	local spellCastTable = {
		castType = CAST_TYPE_CHARGING,
		duration = 2.5,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) RockThrow:ReleaseRock(player) end,
		slowMovePercentage = 30,
		chargingParticle = "particles/rock_throw/charging_particle/charging_particle.vpcf",
		rockThrow_ModifierElements = modifierElements
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
	local modifierElements = player.spellCast.rockThrow_ModifierElements
	local onImpactFunction = nil
	local timeFactor = math.min(2.0, Spells:TimeElapsedSinceCast(player)) / 2.0
	local damageFactor = 0.15 + 0.85 * timeFactor
	local radiusFactor = 0.4 + 0.6 * timeFactor
	local disatnceFactor = 0.05 + 0.95 * timeFactor
	local rockSize = 1
	local rockDamage = 125 * damageFactor
	local earthOnly = false

	local waterTrail = 0
	local fireTrail = 0
	local coldTrail = 0
	local deathTrail = 0
	local lifeTrail = 0
	local steamTrail = 0
	local ice = 0

	for _, element in pairs(modifierElements) do
		if     element == ELEMENT_WATER then waterTrail = 1
		elseif element == ELEMENT_FIRE  then fireTrail = 1
		elseif element == ELEMENT_COLD  then coldTrail = 1
		elseif element == ELEMENT_DEATH then deathTrail = 1
		elseif element == ELEMENT_LIFE  then lifeTrail = 1
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

	local earthInd = table.indexOf(modifierElements, ELEMENT_EARTH)
	if earthInd ~= nil then
		table.remove(modifierElements, earthInd)
		rockSize = 2
		rockDamage = 300 * damageFactor
		if modifierElements[1] == ELEMENT_EARTH then
			rockSize = 3
			rockDamage = 600 * damageFactor
			earthOnly = true
		elseif modifierElements[1] == ELEMENT_DEATH then
			onImpactFunction = function(pos) OmniPulses:OmniDeathPulse(caster, pos, false, {}, radiusFactor, damageFactor) end
		elseif modifierElements[1] == ELEMENT_LIFE then
			onImpactFunction = function(pos) OmniPulses:OmniLifePulse(caster, pos, false, {}, radiusFactor, damageFactor * 2) end
		elseif modifierElements[1] == ELEMENT_FIRE then
			onImpactFunction = function(pos) OmniElementSprays:OmniFireSpray(caster, pos, OMNI_SPELLS_RADIUSES[1] * radiusFactor, false, 100 * damageFactor) end
		elseif modifierElements[1] == ELEMENT_COLD then
			onImpactFunction = function(pos) OmniElementSprays:OmniColdSpray(caster, pos, OMNI_SPELLS_RADIUSES[1] * radiusFactor, false, 55 * damageFactor) end
		elseif modifierElements[1] == ELEMENT_WATER then
			onImpactFunction = function(pos) OmniElementSprays:OmniWaterSpray(caster, pos, OMNI_SPELLS_RADIUSES[1] * radiusFactor, false, false) end
		else
			earthOnly = true
		end
	else
		local deathInd = table.indexOf(modifierElements, ELEMENT_DEATH)
		if deathInd ~= nil then
			table.remove(modifierElements, deathInd)
			onImpactFunction = function(pos) OmniPulses:OmniDeathPulse(caster, pos, false, modifierElements, radiusFactor, damageFactor * 1.5) end
		else
			local lifeInd = table.indexOf(modifierElements, ELEMENT_LIFE)
			if lifeInd ~= nil then
				table.remove(modifierElements, lifeInd)
				onImpactFunction = function(pos) OmniPulses:OmniLifePulse(caster, pos, false, modifierElements, radiusFactor, damageFactor * 2) end
			else
				local fireInd = table.indexOf(modifierElements, ELEMENT_FIRE)
				if fireInd ~= nil then
					table.remove(modifierElements, fireInd)
					if modifierElements[1] == ELEMENT_WATER then
						onImpactFunction = function(pos) OmniElementSprays:OmniSteamSpray(caster, pos, OMNI_SPELLS_RADIUSES[1] * radiusFactor, false, 170 * damageFactor, false) end
					else
						local damage = ((modifierElements[1] == ELEMENT_FIRE) and 212 or 100) * damageFactor
						local radius = OMNI_SPELLS_RADIUSES[(modifierElements[1] == ELEMENT_FIRE) and 2 or 1] * radiusFactor
						onImpactFunction = function(pos) OmniElementSprays:OmniFireSpray(caster, pos, radius, false, damage) end
					end
				else
					local waterInd = table.indexOf(modifierElements, ELEMENT_WATER)
					if waterInd ~= nil then
						table.remove(modifierElements, waterInd)
						if modifierElements[1] == ELEMENT_COLD then
							onImpactFunction = function(pos)
								Spells:ApplyElementDamageAoE(pos, 30, caster, ELEMENT_COLD,  100 * damageFactor, true, false, 1.0)
								Spells:ApplyElementDamageAoE(pos, 30, caster, ELEMENT_WATER, 100 * damageFactor, true, false, 1.0)
							end
						elseif modifierElements[1] == ELEMENT_WATER then
							local radius = OMNI_SPELLS_RADIUSES[(modifierElements[1] == ELEMENT_WATER) and 2 or 1] * radiusFactor
							onImpactFunction = function(pos) OmniElementSprays:OmniWaterSpray(caster, pos, radius, false, false) end
						end
					else
						local coldInd = table.indexOf(modifierElements, ELEMENT_COLD)
						if coldInd ~= nil then
							table.remove(modifierElements, coldInd)
							local radius = OMNI_SPELLS_RADIUSES[(modifierElements[1] == ELEMENT_COLD) and 2 or 1] * radiusFactor
							local damage = ((modifierElements == ELEMENT_COLD) and 113 or 55) * damageFactor
							onImpactFunction = function(pos) OmniElementSprays:OmniColdSpray(caster, pos, radius, false, damage) end
						else
							rockDamage = 135
							earthOnly = true
						end
					end
				end
			end
		end
	end

	local rockRadius = rockSize * 8 + 4
	local distance = ROCK_FLY_DISTANCES[rockSize] * disatnceFactor
	local startOrigin = caster:GetAbsOrigin() + Vector(0, 0, ROCK_START_HEIGHT + rockRadius)
	local rockDummy = Dummy:Create(startOrigin, caster)
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
	ParticleManager:SetParticleControl(particle, 1, Vector(rockSize, earthOnly and 1 or 0, ice))
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