
require("util")
require("camera_slider")
require("move_controller")
require("elements")
require("spells")

if RubicksMagickGameMode == nil then
	RubicksMagickGameMode = class({})
end

function Precache(context)
	PrecacheUnitByNameSync("npc_dota_hero_rubick_rubicks_magick", context)

	Util:Precache(context)
	MoveController:Precache(context)
	Elements:Precache(context)
	Spells:Precache(context)
end

function Activate()
	GameRules.GameMode = RubicksMagickGameMode()
	GameRules.GameMode:InitGameMode()
end

function RubicksMagickGameMode:InitGameMode()
	GameRules:SetSameHeroSelectionEnabled(true)
	GameRules:SetHeroSelectionTime(0.0)
	GameRules:SetPreGameTime(20.0)
	GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_rubick")

	GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)
	GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(RubicksMagickGameMode, "OrderFilter"), self)
	ListenToGameEvent("player_connect_full", Dynamic_Wrap(RubicksMagickGameMode, "OnConnectFull"), self)

	CameraSlider:Init()
	MoveController:Init()
	Elements:Init()
	Spells:Init()
end


function RubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)

    MoveController:PlayerConnected(player)
    Elements:PlayerConnected(player)
    Spells:PlayerConnected(player)
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