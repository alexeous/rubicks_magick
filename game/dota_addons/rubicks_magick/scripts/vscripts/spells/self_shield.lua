require("elements")

MODIFIER_SHIELD_NAMES = {}
MODIFIER_SHIELD_NAMES[ELEMENT_WATER]     = "modifier_shield_water"
MODIFIER_SHIELD_NAMES[ELEMENT_LIFE]      = "modifier_shield_life"
MODIFIER_SHIELD_NAMES[ELEMENT_COLD]      = "modifier_shield_cold"
MODIFIER_SHIELD_NAMES[ELEMENT_LIGHTNING] = "modifier_shield_lightning"
MODIFIER_SHIELD_NAMES[ELEMENT_DEATH]     = "modifier_shield_death"
MODIFIER_SHIELD_NAMES[ELEMENT_EARTH]     = "modifier_shield_earth"
MODIFIER_SHIELD_NAMES[ELEMENT_FIRE]      = "modifier_shield_fire"

SHIELD_DURATION = 20.0

if SelfShield == nil then
	SelfShield = class({})
end

function SelfShield:Precache(context)
	LinkLuaModifier("modifier_shield_water", "modifiers/modifier_shield_water.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_life", "modifiers/modifier_shield_life.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_cold", "modifiers/modifier_shield_cold.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_lightning", "modifiers/modifier_shield_lightning.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_death", "modifiers/modifier_shield_death.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_earth", "modifiers/modifier_shield_earth.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_fire", "modifiers/modifier_shield_fire.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/shield_circles", context)
	PrecacheResource("particle_folder", "particles/shield_life_healing", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/self_shield.vsndevts", context)
end

function SelfShield:PlayerConnected(player)
end


function SelfShield:ApplyElementSelfShield(unit, pickedElements)
	if unit.shieldElements == nil then  unit.shieldElements = {}  end
	if unit.shieldModifiers == nil then  unit.shieldModifiers = {}  end

	SelfShield:RemoveAllShields(unit)
	
	local player = unit:GetPlayerOwner()
	if player ~= nil then
		local spellCastTable = {
			castType = CAST_TYPE_INSTANT,
			duration = 0.2,
			dontMoveWhileCasting = true,
			castingGesture = ACT_DOTA_SPAWN,
			castingGestureRate = 2
		}
		Spells:StartCasting(player, spellCastTable)
	end

	local circleRadius = 1

	-------- TODO: MODIFIER ICON TEXTURES ------------

	table.remove(pickedElements, 1)  -- remove ELEMENT_SHIELD
	if pickedElements[1] ~= nil then
		local kv = { index = 1, circleRadius = circleRadius, duration = SHIELD_DURATION }
		unit.shieldModifiers[1] = unit:AddNewModifier(unit, nil, MODIFIER_SHIELD_NAMES[pickedElements[1]], kv)
		circleRadius = 2
	end

	if pickedElements[2] ~= nil then
		local kv = { index = 2, circleRadius = circleRadius, duration = SHIELD_DURATION }
		unit.shieldModifiers[2] = unit:AddNewModifier(unit, nil, MODIFIER_SHIELD_NAMES[pickedElements[2]], kv)
	end

	unit:EmitSound("SelfShieldApply")
end

function SelfShield:RemoveAllShields(unit)
	if unit.shieldModifiers == nil then
		return
	end
	for _, currentModifier in pairs(unit.shieldModifiers) do
		if not currentModifier:IsNull() then
		 	currentModifier:Destroy()
		end
	end
end