require("libraries/timers")

if ElementSprays == nil then
	ElementSprays = class({})
end

function ElementSprays:Precache(context)	
	PrecacheResource("particle_folder", "particles/element_sprays/steam_spray", context)
	PrecacheResource("particle_folder", "particles/element_sprays/fire_spray", context)
	PrecacheResource("particle_folder", "particles/element_sprays/cold_spray", context)
	PrecacheResource("particle_folder", "particles/element_sprays/water_spray", context)
	
	PrecacheResource("soundfile", "soundevents/rubicks_magick/element_sprays.vsndevts", context)
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
	local hero = player:GetAssignedHero()
	local onTouchFn = function(unit)
		Spells:ApplyElementDamage(unit, hero, ELEMENT_WATER, damage / 2, isWet, 1.0)
		Spells:ApplyElementDamage(unit, hero, ELEMENT_FIRE, damage / 2, false, 1.0)
	end
	local particle = ParticleManager:CreateParticle("particles/element_sprays/steam_spray/steam_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	local particleRecalcFn = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(factor * (0.2 + distanceInd * 0.8), 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(isWet and 1 or 0, 0, 0))		
	end
	local distance = ELEMENT_SPRAY_DISTANCES[distanceInd]
	local soundList = { "SteamSprayLoop1", "SteamSprayLoop2" }
	local spawnSound = "SteamSprayThink"
	ElementSprays:StartElementSprayCasting(player, distance, 4.0, onTouchFn, particle, particleRecalcFn, 110, soundList, spawnSound)
	hero:EmitSound("SteamSprayStart1")
	hero:EmitSound("SteamSprayStart2")
end

function ElementSprays:StartWaterSpray(player, power)
	local distance = ELEMENT_SPRAY_DISTANCES[power] * 0.8
	local hero = player:GetAssignedHero()
	local onTouchFn = ElementSprays:MakeWaterOnTouchFunction(hero, distance)
	local radius = 90 + power * 25
	local particle = ParticleManager:CreateParticle("particles/element_sprays/water_spray/water_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	local particleRecalcFn = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(1 + power * 0.5, 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(factor * (0.2 + power * 0.58), 0, 0))
	end
	local soundList = { "WaterSprayLoop" }
	ElementSprays:StartElementSprayCasting(player, distance, 7.0, onTouchFn, particle, particleRecalcFn, radius, soundList, nil, 0.1)
	hero:EmitSound("WaterSprayStart")
end

function ElementSprays:StartFireSpray(player, power)
	local damages = { 40, 48, 53 }
	local distance = ELEMENT_SPRAY_DISTANCES[power]
	local hero = player:GetAssignedHero()
	local onTouchFn = function(unit)
		Spells:ApplyElementDamage(unit, hero, ELEMENT_FIRE, damages[power], true)
	end
	local radius = 90 + power * 25
	local particle = ParticleManager:CreateParticle("particles/element_sprays/fire_spray/fire_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	local particleRecalcFn = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(1 + power * 0.5, 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(factor * (0.22 + power * 0.8), 0, 0))
	end
	local soundList = { "FireSprayLoop" }
	local spawnSound = "FireSprayThink"
	ElementSprays:StartElementSprayCasting(player, distance, 7.0, onTouchFn, particle, particleRecalcFn, radius, soundList, spawnSound)
	hero:EmitSound("FireSprayStart")
end

function ElementSprays:StartColdSpray(player, power)
	local damages = { 20, 24, 27 }
	local distance = ELEMENT_SPRAY_DISTANCES[power]
	local hero = player:GetAssignedHero()
	local onTouchFn = function(unit)
		Spells:ApplyElementDamage(unit, hero, ELEMENT_COLD, damages[power], true)
	end
	local radius = 90 + power * 25
	local particle = ParticleManager:CreateParticle("particles/element_sprays/cold_spray/cold_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	local particleRecalcFn = function(factor)
		ParticleManager:SetParticleControl(particle, 1, Vector(1 + power * 0.5, 0, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(factor * (0.2 + power * 0.8), 0, 0))
	end
	local soundList = { "ColdSprayLoop1", "ColdSprayLoop2" }
	local spawnSound = "ColdSprayThink"
	ElementSprays:StartElementSprayCasting(player, distance, 7.0, onTouchFn, particle, particleRecalcFn, radius, soundList, spawnSound)
end


function ElementSprays:StartElementSprayCasting(player, distance, duration, onTouchFn, particle, particleRecalcFn, radius, soundList, spawnSound, dummySpawnPeriod)
	local spellCastTable = {
		castType = CAST_TYPE_CONTINUOUS,
		duration = duration,
		minDuration = 0.72,
		slowMovePercentage = 30,
		turnDegsPerSec = 120.0,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		castingGestureTranslate = "black_hole",
		castingGestureRate = 1.5,
		loopSoundList = soundList,
		thinkFunction = function(player) ElementSprays:SpawnSprayDummy(player) end,
		thinkPeriod = dummySpawnPeriod or 0.3,
		elementSprays_Distance = distance,
		elementSprays_Radius = radius,
		elementSprays_onTouchFn = onTouchFn,
		elementSprays_particleRecalcFn = particleRecalcFn,
		elementSprays_spawnSound = spawnSound,
		particle = particle,
		endFunction = function(player)
			ParticleManager:DestroyParticle(player.spellCast.particle, false)
		end
	}
	Spells:StartCasting(player, spellCastTable)
	particleRecalcFn(1.0)
	ElementSprays:SpawnSprayDummy(player, true)
end

function ElementSprays:SpawnSprayDummy(player, isTest)
	local hero = player:GetAssignedHero()
	local position = hero:GetAbsOrigin() + hero:GetForwardVector():Normalized() * 60 + Vector(0, 0, 100)
	local dummy = Util:CreateDummy(position, hero)
	dummy.isTest = isTest
	dummy.caster = hero
	dummy.startTime = GameRules:GetGameTime()
	dummy.startedInsideRoundShield = MagicShield:DoesPointOverlapRoundShields(position)
	dummy.duration = player.spellCast.elementSprays_Distance / ELEMENT_SPRAY_MOVE_SPEED
	dummy.radius = player.spellCast.elementSprays_Radius
	dummy.moveStep = hero:GetForwardVector():Normalized() * ELEMENT_SPRAY_MOVE_STEP
	dummy.touchedUnits = {}
	dummy.onTouchFn = player.spellCast.elementSprays_onTouchFn
	dummy.particleRecalcFn = player.spellCast.elementSprays_particleRecalcFn
	table.insert(ElementSprays.sprayDummiesList, dummy)

	if player.spellCast.elementSprays_spawnSound ~= nil then
		StartSoundEventFromPosition(player.spellCast.elementSprays_spawnSound, hero:GetAbsOrigin())
	end
end

function ElementSprays:MakeWaterOnTouchFunction(caster, distance)
	return function(unit)
		local canPushCaster = Spells:ResistanceLevelTo(caster, ELEMENT_WATER) < 2

		Spells:ApplyElementDamage(unit, caster, ELEMENT_WATER, 1, true)
		local unitToCasterVec = caster:GetAbsOrigin() - unit:GetAbsOrigin()
		local distanceFactor = 1.2 - math.min(1, #unitToCasterVec / distance)
		local vec = caster:GetForwardVector():Normalized() * distanceFactor
		--local upVelocity = Vector(0, 0, 10) * distanceFactor

		if Spells:ResistanceLevelTo(target, ELEMENT_WATER) < 2 then
			MoveController:AddPush(unit, caster, vec * 50--[[ + upVelocity]], vec * 200)
			unit:SetForwardVector(unitToCasterVec)
		elseif canPushCaster and not target.isWall then
			vec = unitToCasterVec:Normalized() * 100 + Vector(0, 0, 10)
			MoveController:AddPush(caster, caster, vec, nil)
		end
	end
end

function ElementSprays:OnElementSprayThink()
	for _, dummy in pairs(ElementSprays.sprayDummiesList) do
		ElementSprays:SprayDummyThink(dummy)
	end
	return ELEMENT_SPRAY_THINK_PERIOD
end

function ElementSprays:SprayDummyThink(dummy)
	local time = GameRules:GetGameTime()
	if time > dummy.startTime + dummy.duration then
		ElementSprays:DestroySprayDummy(dummy)
		return
	end
	if not ElementSprays:MoveSprayDummy(dummy) then
		ElementSprays:DestroySprayDummy(dummy)
		return
	end
	if dummy.isTest then
		return
	end

	local timeFactor = (time - dummy.startTime) / dummy.duration
	local radius = dummy.radius * (0.4 + 0.6 * timeFactor)
	local unitsTouched = Util:FindUnitsInRadius(dummy:GetAbsOrigin(), radius)
	for _, unit in pairs(unitsTouched) do
		if unit ~= dummy.caster and not dummy.touchedUnits[unit] then
			dummy.touchedUnits[unit] = true
			dummy.onTouchFn(unit)
		end
	end
end

function ElementSprays:MoveSprayDummy(dummy)
	local position = dummy:GetAbsOrigin() + dummy.moveStep
	dummy:SetAbsOrigin(position)

	if next(GridNav:GetAllTreesAroundPoint(position, 40, true)) ~= nil then
		return false
	end
	if dummy.startedInsideRoundShield then
		return MagicShield:DoesPointOverlapRoundShields(position)
	else
		return not MagicShield:DoesPointOverlapShields(position)
	end
end

function ElementSprays:DestroySprayDummy(dummy)
	local index = table.indexOf(ElementSprays.sprayDummiesList, dummy)
	table.remove(ElementSprays.sprayDummiesList, index)
	local factor = (GameRules:GetGameTime() - dummy.startTime) / dummy.duration
	dummy.particleRecalcFn(0.2 + 0.8 * factor)
	dummy:Destroy()
end