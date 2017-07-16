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
end

function SelfShield:PlayerConnected(player)
	player.shieldElements = {}
	player.shieldModifiers = {}
end


function SelfShield:ApplyElementSelfShield(player, shieldElements)
	for _, currentModifier in pairs(player.shieldModifiers) do
		if not currentModifier:IsNull() then
		 	currentModifier:Destroy()
		end
	end
	
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.2,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_SPAWN,
		castingGestureRate = 2
	}
	Spells:StartCasting(player, spellCastTable)

	local circleRadius = 1
	local heroEntity = player:GetAssignedHero()

	-------- TODO: MODIFIER ICON TEXTURES ------------

	if shieldElements[1] ~= nil then
		local kv = { index = 1, circleRadius = circleRadius, duration = SHIELD_DURATION }
		player.shieldModifiers[1] = heroEntity:AddNewModifier(heroEntity, nil, MODIFIER_SHIELD_NAMES[shieldElements[1]], kv)
		circleRadius = 2
	end

	if shieldElements[2] ~= nil then
		local kv = { index = 2, circleRadius = circleRadius, duration = SHIELD_DURATION }
		player.shieldModifiers[2] = heroEntity:AddNewModifier(heroEntity, nil, MODIFIER_SHIELD_NAMES[shieldElements[2]], kv)
	end
end

