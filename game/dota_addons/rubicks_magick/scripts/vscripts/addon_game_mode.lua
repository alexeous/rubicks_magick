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
	GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 0.01)

	ListenToGameEvent("player_connect_full", Dynamic_Wrap(CRubicksMagickGameMode, "OnConnectFull"), self)

	CustomGameEventManager:RegisterListener("me_mm", Dynamic_Wrap(CRubicksMagickGameMode, "OnMouseMove"))
	CustomGameEventManager:RegisterListener("me_rd", Dynamic_Wrap(CRubicksMagickGameMode, "OnRightDown"))
	CustomGameEventManager:RegisterListener("me_ru", Dynamic_Wrap(CRubicksMagickGameMode, "OnRightUp"))
	CustomGameEventManager:RegisterListener("me_ld", Dynamic_Wrap(CRubicksMagickGameMode, "OnLeftDown"))
	CustomGameEventManager:RegisterListener("me_lu", Dynamic_Wrap(CRubicksMagickGameMode, "OnLeftUp"))
end


playersRightDown = {}
playersLeftDown = {}
playersMoveTo = {}

function CRubicksMagickGameMode:OnConnectFull(keys)
	local player = PlayerInstanceFromIndex(keys.index + 1)
    local playerID = player:GetPlayerID()
    local heroEntity = CreateHeroForPlayer("npc_dota_hero_rubick", player)
    playersRightDown[playerID] = false;
    playersLeftDown[playerID] = false;
end

function CRubicksMagickGameMode:OnMouseMove(keys)
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
	if heroEntity then
		local oldForward = heroEntity:GetForwardVector()
		local forward = cursorPos - heroEntity:GetAbsOrigin()
		if #forward < 1 then forward = oldForward end

		if playersLeftDown[keys.playerID] then
			heroEntity:SetForwardVector(forward)
		end
		if playersRightDown[keys.playerID] then
			heroEntity:SetForwardVector(forward)
			playersMoveTo[keys.playerID] = cursorPos
		end
	end
end

function CRubicksMagickGameMode:OnRightDown(keys)
	playersRightDown[keys.playerID] = true
	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
	playersMoveTo[keys.playerID] = cursorPos
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	
	local oldForward = heroEntity:GetForwardVector()
	local forward = cursorPos - heroEntity:GetAbsOrigin()
	if #forward < 1 then forward = oldForward end
	heroEntity:SetForwardVector(forward)
	heroEntity:StartGesture(ACT_DOTA_RUN)
end

function CRubicksMagickGameMode:OnRightUp(keys)
	playersRightDown[keys.playerID] = false
end


function CRubicksMagickGameMode:OnLeftDown(keys)
	playersLeftDown[keys.playerID] = true
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	heroEntity:StartGesture(ACT_DOTA_CAST_ABILITY_6)
	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)

	local oldForward = heroEntity:GetForwardVector()
	local forward = cursorPos - heroEntity:GetAbsOrigin()
	if #forward < 1 then forward = oldForward end
	heroEntity:SetForwardVector(forward)
end

function CRubicksMagickGameMode:OnLeftUp(keys)
	playersLeftDown[keys.playerID] = false
end

function CRubicksMagickGameMode:OnThink()
	--local state = GameRules:State_Get()
	for playerID = 0, DOTA_MAX_PLAYERS-1 do
		if playersMoveTo[playerID] ~= nil then
			local heroEntity = PlayerResource:GetPlayer(playerID):GetAssignedHero()
			local moveFrom = heroEntity:GetAbsOrigin()
			local moveTo = playersMoveTo[playerID]
			local vec = moveTo - moveFrom
			local distance = #vec
			local moveStep
			if distance < 12.0 then
				moveStep = vec
				heroEntity:RemoveGesture(ACT_DOTA_RUN)
			else
				moveStep = vec / distance * 12.0
			end
			heroEntity:SetAbsOrigin(moveFrom + moveStep)
		end
	end
	return 0.01
end