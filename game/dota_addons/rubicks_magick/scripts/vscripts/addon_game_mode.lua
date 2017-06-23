if CRubicksMagickGameMode == nil then
	CRubicksMagickGameMode = class({})
end

function Precache( context )
	PrecacheUnitByNameSync("npc_dota_hero_rubick_rubicks_magick", context)
end

function Activate()
	GameRules.GameMode = CRubicksMagickGameMode()
	GameRules.GameMode:InitGameMode()
end

function CRubicksMagickGameMode:InitGameMode()
	GameRules:SetSameHeroSelectionEnabled(true)
	GameRules:SetHeroSelectionTime(0.0)
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )

	ListenToGameEvent("player_connect_full", Dynamic_Wrap(CRubicksMagickGameMode, "OnConnectFull"), self)
end

function CRubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)
    CreateHeroForPlayer("npc_dota_hero_rubick", player)
    --[[local player = EntIndexToHScript(keys.index + 1)
    local playerID = player:GetPlayerID()
    if playerID < DOTA_MAX_PLAYERS then
        local hero = CreateHeroForPlayer("npc_dota_hero_rubick" , player)
    end]]
end

function CRubicksMagickGameMode:OnThink()
	local state = GameRules:State_Get()
	return 1
end