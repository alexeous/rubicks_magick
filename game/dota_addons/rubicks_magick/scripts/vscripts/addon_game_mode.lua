
require("move_controller")

if RubicksMagickGameMode == nil then
	RubicksMagickGameMode = class({})
end

function Precache(context)
	PrecacheUnitByNameSync("npc_dota_hero_rubick_rubicks_magick", context)
	PrecacheResource("particle", "particles/ui_mouseactions/clicked_basemove.vpcf", context)
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

	RubicksMagickGameMode:Init()
end


function RubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)
    local playerID = player:GetPlayerID()
    local heroEntity = CreateHeroForPlayer("npc_dota_hero_rubick", player)
    heroEntity:SetHullRadius(0)
    RubicksMagickMoveController:PlayerConnected(playerID)
end

function RubicksMagickGameMode:OrderFilter(keys)
	return false
end

function RubicksMagickGameMode:OnThink()
	--local state = GameRules:State_Get()
	return 2
end