require("elements")

MODIFIER_SHIELD_NAMES = {}
MODIFIER_SHIELD_NAMES[ELEMENT_WATER]     = "modifier_shield_water_lua"
MODIFIER_SHIELD_NAMES[ELEMENT_LIFE]      = "modifier_shield_life_lua"
MODIFIER_SHIELD_NAMES[ELEMENT_COLD]      = "modifier_shield_cold_lua"
MODIFIER_SHIELD_NAMES[ELEMENT_LIGHTNING] = "modifier_shield_lightning_lua"
MODIFIER_SHIELD_NAMES[ELEMENT_DEATH]     = "modifier_shield_death_lua"
MODIFIER_SHIELD_NAMES[ELEMENT_EARTH]     = "modifier_shield_earth_lua"
MODIFIER_SHIELD_NAMES[ELEMENT_FIRE]      = "modifier_shield_fire_lua"

SHIELD_DURATION = 20.0

if SelfShield == nil then
	SelfShield = class({})
end

function SelfShield:Precache(context)
	LinkLuaModifier("modifier_shield_water_lua", "modifiers/modifier_shield_water_lua.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_life_lua", "modifiers/modifier_shield_life_lua.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_cold_lua", "modifiers/modifier_shield_cold_lua.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_lightning_lua", "modifiers/modifier_shield_lightning_lua.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_death_lua", "modifiers/modifier_shield_death_lua.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_earth_lua", "modifiers/modifier_shield_earth_lua.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_shield_fire_lua", "modifiers/modifier_shield_fire_lua.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/shield_circles", context)
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

	player.shieldElements = shieldElements
	Spells:StartCastingGesture(player, ACT_DOTA_SPAWN, 2)
	Spells:MarkStartedCasting(player, true, 0.2)

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

