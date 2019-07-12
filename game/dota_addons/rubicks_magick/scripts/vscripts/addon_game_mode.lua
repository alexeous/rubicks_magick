require("util")
require("move_controller")
require("elements")
require("spells")

if RubicksMagickGameMode == nil then
	RubicksMagickGameMode = class({})
end

function Precache(context)
	PrecacheUnitByNameSync("npc_dota_hero_rubick_rubicks_magick", context)
	PrecacheResource("soundfile", "soundevents/rubicks_magick/common.vsndevts", context)

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
	GameRules:SetPreGameTime(1.0)

	GameRules:GetGameModeEntity():SetCameraDistanceOverride(1090)
	GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_rubick")

	GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)
	ListenToGameEvent("player_connect_full", Dynamic_Wrap(RubicksMagickGameMode, "OnConnectFull"), self)

	MoveController:Init()
	Elements:Init()
	Spells:Init()

	Timers:CreateTimer(1, function() GameRules:SetCustomGameSetupRemainingTime(0) end)
	Timers:CreateTimer(function() 
		for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local hero = player:GetAssignedHero()
				if hero ~= nil and not hero:IsAlive() then
					hero:RespawnHero(false, false)
				end
			end
		end
		return 2
	end)
end


function RubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)

    MoveController:PlayerConnected(player)
    Elements:PlayerConnected(player)
    Spells:PlayerConnected(player)
end

function RubicksMagickGameMode:OnThink()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local hero = player:GetAssignedHero()
			if hero ~= nil then
				AddFOWViewer(hero:GetTeamNumber(), hero:GetAbsOrigin(), hero:GetCurrentVisionRange(), 1, false)
			end
		end
	end
	return 0.2
end