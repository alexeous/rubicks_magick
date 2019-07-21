require("spells/generic_wall")

if StoneWall == nil then
	StoneWall = class({})
end

function StoneWall:Precache(context)
	LinkLuaModifier("modifier_stone_wall", "modifiers/modifier_stone_wall.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/stone_wall", context)
	PrecacheResource("particle_folder", "particles/stone_wall/stone_wall_elements", context)
end

function StoneWall:PlayerConnected(player)
end


function StoneWall:PlaceStoneWallSpell(player, modifierElement)
	local caster = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.75,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.0,
		castingGestureTranslate = "shadowraze",
		thinkPeriod = 0.17,
		thinkFunction = function(player) 
			player.spellCast.thinkFunction = nil
			Spells:RemoveMagicShieldAndSolidWalls(player)
			StoneWall:PlaceStoneWall(caster, modifierElement)
		end
	}

	Spells:StartCasting(player, spellCastTable)
	GenericWall:KnockbackAllAwayFromWall(caster)
	ParticleManager:CreateParticle("particles/stone_wall/stone_wall_hero_wave.vpcf", PATTACH_ABSORIGIN, caster)
end

function StoneWall:PlaceStoneWall(caster, modifierElement)
	caster.blastedWallsCount = 0

	local wallUnitNumber = modifierElement ~= nil and 4 or 2
	local immuneElements = StoneWall:CalcImmuneElements(modifierElement)
	
	local onKilledCallback = function(wall, isQuietKill)
		StoneWall:OnWallKilled(wall, caster, isQuietKill)
	end
	local wallUnits = GenericWall:CreateWallUnits(caster, wallUnitNumber, 40, immuneElements, onKilledCallback)
	for _, wall in pairs(wallUnits) do
		StoneWall:InitWallUnit(wall, caster, modifierElement)
		Spells:RegisterCastedSolidWall(caster, wall)
	end
end

function StoneWall:CalcImmuneElements(modifierElement)
	local immuneElements = { ELEMENT_EARTH }
	if modifierElement ~= ELEMENT_WATER then
		table.insert(immuneElements, ELEMENT_LIGHTNING)
	end
	if modifierElement ~= nil and modifierElement ~= ELEMENT_EARTH then
		table.insert(immuneElements, modifierElement)
	end
	return immuneElements
end

function StoneWall:InitWallUnit(wall, caster, modifierElement)
	wall.modifierElement = modifierElement
	wall:SetHullRadius(50)
	wall.isSolidWall = true
	wall:AddNewModifier(caster, nil, "modifier_stone_wall", {})

	if modifierElement ~= nil and modifierElement ~= ELEMENT_EARTH then
		local pos = wall:GetAbsOrigin()
		local radius = OMNI_SPELLS_RADIUSES[1] * 1.1
		local blastFuncTable = {
			[ELEMENT_DEATH] = function(powerFactor) OmniPulses:OmniDeathPulse(caster, pos, false, { ELEMENT_DEATH }, nil, nil, radius, 215 * powerFactor) end,
			[ELEMENT_LIFE] = function(powerFactor) OmniPulses:OmniLifePulse(caster, pos, false, { ELEMENT_LIFE }, nil, nil, radius, 85 * powerFactor) end,
			[ELEMENT_FIRE] = function(powerFactor) OmniElementSprays:OmniFireSpray(caster, pos, radius, false, 200 * powerFactor) end,
			[ELEMENT_COLD] = function(powerFactor) OmniElementSprays:OmniColdSpray(caster, pos, radius, false, 70 * powerFactor) end,
			[ELEMENT_WATER] = function(powerFactor) OmniElementSprays:OmniWaterSpray(caster, pos, radius, false, true) end
		}
		wall.blastFunction = blastFuncTable[modifierElement]
	end
end

function StoneWall:OnWallKilled(wall, caster, isQuietKill)
	if not isQuietKill and wall.isReadyForBlast then
		StoneWall:BlastWall(wall, caster)
	end	
	Spells:UnregisterCastedSolidWall(caster, wall)
end

function StoneWall:MakeReadyForBlast(wall)
	wall.isReadyForBlast = true
end

function StoneWall:BlastWall(wall, caster)
	caster.blastedWallsCount = caster.blastedWallsCount + 1
	if wall.blastFunction ~= nil then
		local powerFactor = 1.0 / caster.blastedWallsCount
		wall.blastFunction(powerFactor)
	end
end