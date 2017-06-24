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
	GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)

	ListenToGameEvent("player_connect_full", Dynamic_Wrap(CRubicksMagickGameMode, "OnConnectFull"), self)

	CustomGameEventManager:RegisterListener("me_mm", Dynamic_Wrap(CRubicksMagickGameMode, "OnMouseMove"))
	CustomGameEventManager:RegisterListener("me_rd", Dynamic_Wrap(CRubicksMagickGameMode, "OnRightDown"))
	CustomGameEventManager:RegisterListener("me_ru", Dynamic_Wrap(CRubicksMagickGameMode, "OnRightUp"))
end


playersRightDown = {}

function CRubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)
    CreateHeroForPlayer("npc_dota_hero_rubick", player)
    playersRightDown[player:GetPlayerID()] = false;
end

function CRubicksMagickGameMode:OnMouseMove(keys)
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
	heroEntity:SetForwardVector(cursorPos - heroEntity:GetAbsOrigin())
	if playersRightDown[keys.playerID] then
		heroEntity:MoveToPosition(cursorPos)
	end
end

function CRubicksMagickGameMode:OnRightDown(keys)
	playersRightDown[keys.playerID] = true;
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
	heroEntity:MoveToPosition(cursorPos)
end

function CRubicksMagickGameMode:OnRightUp(keys)
	playersRightDown[keys.playerID] = false;
end

function CRubicksMagickGameMode:OnThink()
	local state = GameRules:State_Get()
	return 1
end