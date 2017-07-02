
require("move_controller")
require("elements")

if RubicksMagickGameMode == nil then
	RubicksMagickGameMode = class({})
end

function Precache(context)
	PrecacheUnitByNameSync("npc_dota_hero_rubick_rubicks_magick", context)
	PrecacheResource("particle", "particles/ui_mouseactions/clicked_basemove.vpcf", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_invoker", context)

	PrecacheResource("particle_folder", "particles/orbs/fire_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/death_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/cold_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/lightning_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/shield_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/earth_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/life_orb", context)
	PrecacheResource("particle_folder", "particles/orbs/water_orb", context)
end

function Activate()
	GameRules.GameMode = RubicksMagickGameMode()
	GameRules.GameMode:InitGameMode()
end

function RubicksMagickGameMode:InitGameMode()
	GameRules:SetSameHeroSelectionEnabled(true)
	GameRules:SetHeroSelectionTime(0.0)
	GameRules:SetPreGameTime(20.0)

	GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)
	GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(RubicksMagickGameMode, "OrderFilter"), self)
	ListenToGameEvent("player_connect_full", Dynamic_Wrap(RubicksMagickGameMode, "OnConnectFull"), self)

	MoveController:Init()
	Elements:Init()
end


function RubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)
    local playerID = player:GetPlayerID()
    local heroEntity = CreateHeroForPlayer("npc_dota_hero_rubick", player)
    heroEntity:SetHullRadius(0)
    MoveController:PlayerConnected(player)
    Elements:PlayerConnected(player)
end

function RubicksMagickGameMode:OrderFilter(keys)
	return false
end

function RubicksMagickGameMode:OnThink()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local heroEntity = player:GetAssignedHero()
			if heroEntity ~= nil then
				AddFOWViewer(heroEntity:GetTeamNumber(), heroEntity:GetAbsOrigin(), heroEntity:GetCurrentVisionRange(), 1, false)
			end
		end
	end
	return 0.2
end