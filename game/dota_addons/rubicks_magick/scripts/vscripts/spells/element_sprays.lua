require("libraries/timers")

if ElementSprays == nil then
	ElementSprays = class({})
end

function ElementSprays:Precache(context)
end

function ElementSprays:PlayerConnected(player)

end

ELEMENT_SPRAY_DISTANCES = { 260, 450, 600 }
ELEMENT_SPRAY_THINK_PERIOD = 0.05
ELEMENT_SPRAY_MOVE_SPEED = 720
ELEMENT_SPRAY_MOVE_STEP = ELEMENT_SPRAY_MOVE_SPEED * ELEMENT_SPRAY_THINK_PERIOD

function ElementSprays:Init()
	ElementSprays.sprayDummiesList = {}
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(ElementSprays, "OnElementSprayThink"), "ElementSprayThink", ELEMENT_SPRAY_THINK_PERIOD)
end


function ElementSprays:StartSteamSpray(player, modifierElement)
	local isWet = modifierElement == ELEMENT_WATER
	local damage = (modifierElement == ELEMENT_FIRE) and 60 or 30
	local heroEntity = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_CONTINUOUS,
		duration = 5.0,
		slowMovePercentage = 30,
		turnDegsPerSec = 120.0,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		castingGestureTranslate = "black_hole",
		castingGestureRate = 1.5,
		thinkFunction = function(player) ElementSprays:SpawnSprayDummy(player) end,
		thinkPeriod = 0.3,
		elementSprays_Distance = ELEMENT_SPRAY_DISTANCES[1],
		elementSprays_OnTouchFunction = function(unit)
			Spells:ApplyElementDamage(unit, heroEntity, ELEMENT_WATER, damage / 2, isWet, 1.0)
			Spells:ApplyElementDamage(unit, heroEntity, ELEMENT_FIRE, damage / 2, false, 1.0)
		end,
		endFunction = function(player) ParticleManager:DestroyParticle(player.spellCast.particle, false) end
	}
	local particle = ParticleManager:CreateParticle("particles/element_sprays/steam_spray/steam_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, heroEntity)
	ParticleManager:SetParticleControl(particle, 2, Vector(isWet and 1 or 0, 0, 0))
	spellCastTable.particle = particle
	Spells:StartCasting(player, spellCastTable)
	ElementSprays:SpawnSprayDummy(player)
end

function ElementSprays:StartWaterSpray(player, power)
	-------- TODO ---------
end

function ElementSprays:StartFireSpray(player, power)
	-------- TODO ---------
end

function ElementSprays:StartColdSpray(player, power)
	-------- TODO ---------
end


function ElementSprays:SpawnSprayDummy(player)
	local heroEntity = player:GetAssignedHero()
	local position = heroEntity:GetAbsOrigin() + heroEntity:GetForwardVector():Normalized() * 60 + Vector(0, 0, 100)
	local duration = player.spellCast.elementSprays_Distance / ELEMENT_SPRAY_MOVE_SPEED
	local sprayDummy = Dummy:Create(position, heroEntity)
	sprayDummy.caster = heroEntity
	sprayDummy.endTime = GameRules:GetGameTime() + duration
	sprayDummy.moveStep = heroEntity:GetForwardVector():Normalized() * ELEMENT_SPRAY_MOVE_STEP
	sprayDummy.touchedUnits = {}
	sprayDummy.onTouchFunction = player.spellCast.elementSprays_OnTouchFunction
	table.insert(ElementSprays.sprayDummiesList, sprayDummy)
end

function ElementSprays:OnElementSprayThink()
	for _, sprayDummy in pairs(ElementSprays.sprayDummiesList) do
		if GameRules:GetGameTime() > sprayDummy.endTime then
			ElementSprays:DestroySprayDummy(sprayDummy)
		else
			local origin = sprayDummy:GetAbsOrigin() + sprayDummy.moveStep
			sprayDummy:SetAbsOrigin(origin)

			local trees = GridNav:GetAllTreesAroundPoint(origin, 40, true)
			if next(trees) ~= nil then
				ElementSprays:DestroySprayDummy(sprayDummy)
			else
				local unitsTouched = FindUnitsInRadius(sprayDummy.caster:GetTeamNumber(), origin, nil, 100, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)
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
	sprayDummy:Destroy()
end