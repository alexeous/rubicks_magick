local ICE_WALL_DAMAGE_AREA_RADIUS = 250
local ICE_WALL_DAMAGE_AREA_ANGLE = 160

if ElementWalls == nil then
	ElementWalls = class({})
end

function ElementWalls:Precache(context)
	LinkLuaModifier("modifier_ice_wall", "modifiers/modifier_ice_wall.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/element_walls/ice_wall", context)
end

function ElementWalls:PlayerConnected(player)

end


function ElementWalls:PlaceIceWallSpell(player)
	local caster = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.18,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.2,
		castingGestureTranslate = "wall",
		thinkPeriod = 0.17,
		thinkFunction = function(player) 
			player.spellCast.thinkFunction = nil
			Spells:RemoveMagicShieldAndSolidWalls(player)
			ElementWalls:PlaceIceWall(caster) 
		end
	}

	Spells:StartCasting(player, spellCastTable)
	GenericWall:KnockbackAllAwayFromWall(caster)
end

function ElementWalls:PlaceSteamWall(player)
	-------- TODO ---------
end

function ElementWalls:PlaceWaterWall(player, modifierElement)
	-------- TODO ---------
end

function ElementWalls:PlaceFireWall(player, modifierElement)
	-------- TODO ---------
end

function ElementWalls:PlaceColdWall(player, modifierElement)
	-------- TODO ---------
end

function ElementWalls:PlaceIceWall(caster)
	local immuneElements = { ELEMENT_WATER, ELEMENT_COLD, ELEMENT_LIGHTNING, ELEMENT_EARTH }
	local onKilledCallback = function(wall)
		Spells:UnregisterCastedSolidWall(caster, wall)
	end

	local wallUnits = GenericWall:CreateWallUnits(caster, 4, 40, immuneElements, onKilledCallback)
	for _, wall in pairs(wallUnits) do
		ElementWalls:InitIceWallUnit(caster, wall)
		Spells:RegisterCastedSolidWall(caster, wall)
	end

	ElementWalls:ApplyIceWallDamage(caster, wallUnits)

	caster:EmitSound("PlaceStoneWall1")
end

function ElementWalls:InitIceWallUnit(caster, wall)
	wall:MakePhantomBlocker()
	wall:SetHullRadius(65)
	wall.isSolidWall = true
	wall:AddNewModifier(caster, nil, "modifier_ice_wall", {})
end

function ElementWalls:ApplyIceWallDamage(caster, wallUnits)
	local center = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector()
	local units = Util:FindUnitsInSector(center, ICE_WALL_DAMAGE_AREA_RADIUS, forward, ICE_WALL_DAMAGE_AREA_ANGLE)
	for _, unit in pairs(units) do
		if unit ~= caster then
			Spells:ApplyElementDamage(unit, caster, ELEMENT_WATER, 100, false, nil, true)
			Spells:ApplyElementDamage(unit, caster, ELEMENT_COLD, 100, false, nil, true)
		end
	end
end