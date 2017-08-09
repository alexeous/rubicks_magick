require("libraries/timers")

if ElementSprays == nil then
	ElementSprays = class({})
end

function ElementSprays:Precache(context)	
	PrecacheResource("particle_folder", "particles/element_sprays/steam_spray", context)
	PrecacheResource("particle_folder", "particles/element_sprays/fire_spray", context)
	PrecacheResource("particle_folder", "particles/element_sprays/cold_spray", context)
	PrecacheResource("particle_folder", "particles/element_sprays/water_spray", context)
end

function ElementSprays:PlayerConnected(player)

end

ELEMENT_SPRAY_DISTANCES = { 350, 600, 900 }
ELEMENT_SPRAY_THINK_PERIOD = 0.05
ELEMENT_SPRAY_MOVE_SPEED = 1500
ELEMENT_SPRAY_MOVE_STEP = ELEMENT_SPRAY_MOVE_SPEED * ELEMENT_SPRAY_THINK_PERIOD

function ElementSprays:Init()
	ElementSprays.sprayDummiesList = {}
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(ElementSprays, "OnElementSprayThink"), "ElementSprayThink", ELEMENT_SPRAY_THINK_PERIOD)
end


function ElementSprays:StartSteamSpray(player, modifierElement)
	local isWet = modifierElement == ELEMENT_WATER
	local damage = (modifierElement == ELEMENT_FIRE) and 75 or 63
	local distanceInd = (modifierElement == ELEMENT_WATER) and 2 or 1
	local heroEntity = player:GetAssignedHero()
	local onTouchFunction = function(unit)
		Spells:ApplyElementDamage(unit, heroEntity, ELEMENT_WATER, damage / 2, isWet, 1.0)
		Spells:ApplyElementDamage(unit, heroEntity, ELEMENT_FIRE, damage / 2, false, 1.0)
	end
	local particle = ParticleManager:CreateParticle("particles/element_sprays/steam_spray/steam_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, heroEntity)
	local particleRecalcFunction = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(factor * (0.2 + distanceInd * 0.8), 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(isWet and 1 or 0, 0, 0))		
	end	
	ElementSprays:StartElementSprayCasting(player, ELEMENT_SPRAY_DISTANCES[distanceInd], onTouchFunction, particle, particleRecalcFunction, 110)
end

function ElementSprays:StartWaterSpray(player, power)
	local distance = ELEMENT_SPRAY_DISTANCES[power] * 0.8
	local heroEntity = player:GetAssignedHero()
	local onTouchFunction = function(unit)
		Spells:ApplyElementDamage(unit, heroEntity, ELEMENT_WATER, 1, true)
		local unitToCasterVec = heroEntity:GetAbsOrigin() - unit:GetAbsOrigin()
		local distanceFactor = 1.2 - math.min(1, #unitToCasterVec / distance)
		local vec = heroEntity:GetForwardVector():Normalized() * distanceFactor
		local upVelocity = Vector(0, 0, 10) * distanceFactor
		local success = Spells:AddWaterPush(unit, heroEntity, vec * 50 + upVelocity, vec * 200)
		if success then
			unit:SetForwardVector(unitToCasterVec)
		else
			vec = unitToCasterVec:Normalized() * 100 + Vector(0, 0, 10)
			Spells:AddWaterPush(heroEntity, heroEntity, vec, nil)
		end
	end
	local radius = 90 + power * 25
	local particle = ParticleManager:CreateParticle("particles/element_sprays/water_spray/water_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, heroEntity)
	local particleRecalcFunction = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(1 + power * 0.5, 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(factor * (0.2 + power * 0.58), 0, 0))
	end
	ElementSprays:StartElementSprayCasting(player, distance, onTouchFunction, particle, particleRecalcFunction, radius, 0.1)
end

function ElementSprays:StartFireSpray(player, power)
	local damages = { 40, 48, 53 }
	local distance = ELEMENT_SPRAY_DISTANCES[power]
	local heroEntity = player:GetAssignedHero()
	local onTouchFunction = function(unit)
		Spells:ApplyElementDamage(unit, heroEntity, ELEMENT_FIRE, damages[power], true)
	end
	local radius = 90 + power * 25
	local particle = ParticleManager:CreateParticle("particles/element_sprays/fire_spray/fire_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, heroEntity)
	local particleRecalcFunction = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(1 + power * 0.5, 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(factor * (0.2 + power * 0.8), 0, 0))
	end
	ElementSprays:StartElementSprayCasting(player, distance, onTouchFunction, particle, particleRecalcFunction, radius)
end

function ElementSprays:StartColdSpray(player, power)
	local damages = { 20, 24, 27 }
	local distance = ELEMENT_SPRAY_DISTANCES[power]
	local heroEntity = player:GetAssignedHero()
	local onTouchFunction = function(unit)
		Spells:ApplyElementDamage(unit, heroEntity, ELEMENT_COLD, damages[power], true)
	end
	local radius = 90 + power * 25
	local particle = ParticleManager:CreateParticle("particles/element_sprays/cold_spray/cold_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, heroEntity)
	local particleRecalcFunction = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(1 + power * 0.5, 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(factor * (0.2 + power * 0.8), 0, 0))
	end
	ElementSprays:StartElementSprayCasting(player, distance, onTouchFunction, particle, particleRecalcFunction, radius)
end


function ElementSprays:StartElementSprayCasting(player, distance, onTouchFunction, particle, particleRecalcFunction, radius, dummySpawnPeriod)
	local spellCastTable = {
		castType = CAST_TYPE_CONTINUOUS,
		duration = 5.0,
		slowMovePercentage = 30,
		turnDegsPerSec = 120.0,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		castingGestureTranslate = "black_hole",
		castingGestureRate = 1.5,
		thinkFunction = function(player) ElementSprays:SpawnSprayDummy(player) end,
		thinkPeriod = dummySpawnPeriod or 0.3,
		elementSprays_Distance = distance,
		elementSprays_Radius = radius,
		elementSprays_OnTouchFunction = onTouchFunction,
		elementSprays_ParticleRecalcFunction = particleRecalcFunction,
		particle = particle,
		endFunction = function(player) ParticleManager:DestroyParticle(player.spellCast.particle, false) end
	}
	Spells:StartCasting(player, spellCastTable)
	particleRecalcFunction(1.0)
	ElementSprays:SpawnSprayDummy(player, true)
end

function ElementSprays:SpawnSprayDummy(player, isTest)
	local heroEntity = player:GetAssignedHero()
	local position = heroEntity:GetAbsOrigin() + heroEntity:GetForwardVector():Normalized() * 60 + Vector(0, 0, 100)
	local sprayDummy = Util:CreateDummy(position, heroEntity)
	sprayDummy.isTest = isTest
	sprayDummy.caster = heroEntity
	sprayDummy.startTime = GameRules:GetGameTime()
	sprayDummy.duration = player.spellCast.elementSprays_Distance / ELEMENT_SPRAY_MOVE_SPEED
	sprayDummy.radius = player.spellCast.elementSprays_Radius
	sprayDummy.moveStep = heroEntity:GetForwardVector():Normalized() * ELEMENT_SPRAY_MOVE_STEP
	sprayDummy.touchedUnits = {}
	sprayDummy.onTouchFunction = player.spellCast.elementSprays_OnTouchFunction
	sprayDummy.particleRecalcFunction = player.spellCast.elementSprays_ParticleRecalcFunction
	table.insert(ElementSprays.sprayDummiesList, sprayDummy)
end

function ElementSprays:OnElementSprayThink()
	local time = GameRules:GetGameTime()
	for _, sprayDummy in pairs(ElementSprays.sprayDummiesList) do
		if time > sprayDummy.startTime + sprayDummy.duration then
			ElementSprays:DestroySprayDummy(sprayDummy)
		else
			local origin = sprayDummy:GetAbsOrigin() + sprayDummy.moveStep
			sprayDummy:SetAbsOrigin(origin)

			local trees = GridNav:GetAllTreesAroundPoint(origin, 40, true)
			if next(trees) ~= nil then
				ElementSprays:DestroySprayDummy(sprayDummy)
			elseif not sprayDummy.isTest then
				local timeFactor = (time - sprayDummy.startTime) / sprayDummy.duration
				local radius = sprayDummy.radius * (0.4 + 0.6 * timeFactor)
				local unitsTouched = Util:FindUnitsInRadius(origin, radius)
				for _, unit in pairs(unitsTouched) do
					if unit ~= sprayDummy.caster and not sprayDummy.touchedUnits[unit] then
						sprayDummy.touchedUnits[unit] = true
						sprayDummy.onTouchFunction(unit)
					end
				end
			end
		end
	end
	return ELEMENT_SPRAY_THINK_PERIOD
end

function ElementSprays:DestroySprayDummy(sprayDummy)
	local index = table.indexOf(ElementSprays.sprayDummiesList, sprayDummy)
	table.remove(ElementSprays.sprayDummiesList, index)
	local factor = (GameRules:GetGameTime() - sprayDummy.startTime) / sprayDummy.duration
	sprayDummy.particleRecalcFunction(factor)
	sprayDummy:Destroy()
end