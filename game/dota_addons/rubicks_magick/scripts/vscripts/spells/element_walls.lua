local ICE_WALL_DAMAGE_AREA_RADIUS = 250
local ICE_WALL_DAMAGE_AREA_ANGLE = 160

if ElementWalls == nil then
	ElementWalls = class({})
end

function ElementWalls:Precache(context)
	LinkLuaModifier("modifier_ice_wall", "modifiers/modifier_ice_wall.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_element_wall", "modifiers/modifier_element_wall.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/element_walls/ice_wall", context)
	
	PrecacheResource("soundfile", "soundevents/rubicks_magick/element_walls.vsndevts", context)
	
	PrecacheResource("soundfile", "sounds/weapons/hero/tusk/ice_shards.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/ancient_apparition/ice_vortex_cast.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/ancient_apparition/attack_impact1.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/ancient_apparition/attack_impact2.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/ancient_apparition/attack_impact3.vsnd", context)
end

function ElementWalls:PlayerConnected(player)

end


function ElementWalls:PlaceWaterWallSpell(player, modifierElement)
	ElementWalls:GenericStartCasting(player, ELEMENT_WATER, modifierElement)
end

function ElementWalls:PlaceColdWallSpell(player, modifierElement)
	ElementWalls:GenericStartCasting(player, ELEMENT_COLD, modifierElement)
end

function ElementWalls:PlaceFireWallSpell(player, modifierElement)
	ElementWalls:GenericStartCasting(player, ELEMENT_FIRE, modifierElement)
end

function ElementWalls:PlaceSteamWallSpell(player)
	ElementWalls:GenericStartCasting(player, PSEUDO_ELEMENT_STEAM, nil)
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
	ElementWalls:ApplyIceWallDamage(caster)
	ParticleManager:CreateParticle("particles/element_walls/ice_wall/ice_wall_hero_wave.vpcf", PATTACH_ABSORIGIN, caster)
end


function ElementWalls:GenericStartCasting(player, element, modifierElement)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.75,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.0,
		castingGestureTranslate = "wall",
		thinkPeriod = 0.17,
		thinkFunction = function(player) 
			player.spellCast.thinkFunction = nil
			Spells:RemoveElementWalls(player)
			ElementWalls:GenericPlaceWallUnits(player:GetAssignedHero(), element, modifierElement)
		end
	}
	Spells:StartCasting(player, spellCastTable)
end

function ElementWalls:GenericPlaceWallUnits(caster, element, modifierElement)
	local wallUnitNumber = modifierElement ~= nil and 4 or 2

	local immuneElements = table.except(ALL_ELEMENTS_INCLUDING_PSEUDO, ElementWalls:GetWallVulnerabilityElements(element))

	local damage = ElementWalls:GetWallDamage(element)
	local sharedApplyingCurriedFunc = HP:MakeSharedApplyingCurried(damage)
	local doPush = element == ELEMENT_WATER
	local effectFunc = function(wall, target, applyingNumber)
		if HP:ApplyElement(target, caster, element, sharedApplyingCurriedFunc(applyingNumber)) and doPush then
			MoveController:Knockback(target, caster, wall:GetAbsOrigin(), 80)
		end
	end

	local onKilledCallback = function(wall)
		Spells:UnregisterCastedElementWall(caster, wall)
	end
	
	local wallUnits = GenericWall:CreateWallUnits(caster, wallUnitNumber, 40, immuneElements, onKilledCallback)
	for _, wall in pairs(wallUnits) do
		ElementWalls:GenericInitWallUnit(wall, caster, element, effectFunc)
		Spells:RegisterCastedElementWall(caster, wall)
	end
end

function ElementWalls:GetWallVulnerabilityElements(wallElement)
	local vulnerabilityElementsTable = {
		[ELEMENT_WATER]			= { ELEMENT_FIRE },
		[ELEMENT_COLD]			= { ELEMENT_FIRE },
		[ELEMENT_FIRE]			= { ELEMENT_WATER, ELEMENT_COLD },
		[PSEUDO_ELEMENT_STEAM]	= { ELEMENT_COLD }
	}
	return vulnerabilityElementsTable[wallElement]
end

function ElementWalls:GetWallDamage(wallElement)
	local damageTable = {
		[ELEMENT_WATER]			= 1,
		[ELEMENT_COLD]			= 45,
		[ELEMENT_FIRE]			= 80,
		[PSEUDO_ELEMENT_STEAM]	= 100
	}
	return damageTable[wallElement]
end

function ElementWalls:GenericInitWallUnit(wall, caster, element, effectFunc)
	wall.isElementWall = true
	wall.effectFunc = effectFunc
	wall:AddNewModifier(caster, nil, "modifier_element_wall", { element = element })
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

	caster:EmitSound("PlaceIceWall1")
	caster:EmitSound("PlaceIceWall2")
end

function ElementWalls:InitIceWallUnit(caster, wall)
	wall:MakePhantomBlocker()
	wall:SetHullRadius(65)
	wall.isSolidWall = true
	wall:AddNewModifier(caster, nil, "modifier_ice_wall", {})
end

function ElementWalls:ApplyIceWallDamage(caster)
	local center = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector()
	local units = Util:FindUnitsInSector(center, ICE_WALL_DAMAGE_AREA_RADIUS, forward, ICE_WALL_DAMAGE_AREA_ANGLE)
	for _, unit in pairs(units) do
		if unit ~= caster then
			HP:ApplyElement(unit, caster, PSEUDO_ELEMENT_ICE, 200)
		end
	end
end