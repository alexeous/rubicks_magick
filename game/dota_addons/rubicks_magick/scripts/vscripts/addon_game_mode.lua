
require("move_controller")

if RubicksMagickGameMode == nil then
	RubicksMagickGameMode = class({})
end

function Precache( context )
	PrecacheUnitByNameSync("npc_dota_hero_rubick_rubicks_magick", context)
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
	GameRules:GetGameModeEntity():SetThink(OnMoveHeroesThink, "MoveHeroesThink", 1)

	ListenToGameEvent("player_connect_full", Dynamic_Wrap(RubicksMagickGameMode, "OnConnectFull"), self)

	CustomGameEventManager:RegisterListener("me_mm", Dynamic_Wrap(RubicksMagickMoveController, "OnMouseMove"))
	CustomGameEventManager:RegisterListener("me_rd", Dynamic_Wrap(RubicksMagickMoveController, "OnRightDown"))
	CustomGameEventManager:RegisterListener("me_ru", Dynamic_Wrap(RubicksMagickMoveController, "OnRightUp"))
	CustomGameEventManager:RegisterListener("me_ld", Dynamic_Wrap(RubicksMagickMoveController, "OnLeftDown"))
	CustomGameEventManager:RegisterListener("me_lu", Dynamic_Wrap(RubicksMagickMoveController, "OnLeftUp"))
end


function RubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)
    local playerID = player:GetPlayerID()
    local heroEntity = CreateHeroForPlayer("npc_dota_hero_rubick", player)
    heroEntity:SetHullRadius(0)
    RubicksMagickMoveController:InitPlayer(playerID)
end


function RubicksMagickGameMode:OnThink()
	--local state = GameRules:State_Get()
	return 2
end