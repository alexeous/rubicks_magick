
if RubicksMagickMoveController == nil then
	RubicksMagickMoveController = class({})
end

playersRightDown = {}
playersLeftDown = {}
playersMoveTo = {}

function OnMoveHeroesThink()
	local MOVE_PER_THINK = 11.0
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		if playersMoveTo[playerID] ~= nil then
			local heroEntity = PlayerResource:GetPlayer(playerID):GetAssignedHero()
			local moveFrom = heroEntity:GetAbsOrigin()
			local vec = playersMoveTo[playerID] - moveFrom
			local distance = #vec
			local newOrigin
			if distance < MOVE_PER_THINK then
				newOrigin = moveFrom + vec
				heroEntity:RemoveGesture(ACT_DOTA_RUN)
				playersMoveTo[playerID] = nil
			else
				newOrigin = moveFrom + (vec / distance) * MOVE_PER_THINK
			end
			FindClearSpaceForUnit(heroEntity, newOrigin, false)
		end
	end
	return 0.03
end

function RubicksMagickMoveController:InitPlayer(playerID)
	playersRightDown[playerID] = false;
    playersLeftDown[playerID] = false;
end

function HeroLookAt(heroEntity, targetPos)
	if heroEntity ~= nil then
		local oldForward = heroEntity:GetForwardVector()
		local forward = targetPos - heroEntity:GetAbsOrigin()
		if #forward < 1 then 	-- prevent from zero-vector
			forward = oldForward 
		end
		heroEntity:SetForwardVector(forward)
	end
end

function RubicksMagickMoveController:OnMouseMove(keys)
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
	if playersLeftDown[keys.playerID] then
		HeroLookAt(heroEntity, cursorPos)
	end
	if playersRightDown[keys.playerID] then
		HeroLookAt(heroEntity, cursorPos)
		if playersMoveTo[keys.playerID] == nil then
			heroEntity:StartGesture(ACT_DOTA_RUN)
		end
		playersMoveTo[keys.playerID] = cursorPos
	end
end	


function RubicksMagickMoveController:OnRightDown(keys)
	playersRightDown[keys.playerID] = true

	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
	playersMoveTo[keys.playerID] = cursorPos

	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	HeroLookAt(heroEntity, cursorPos)
	heroEntity:StartGesture(ACT_DOTA_RUN)
end

function RubicksMagickMoveController:OnRightUp(keys)
	playersRightDown[keys.playerID] = false
end


function RubicksMagickMoveController:OnLeftDown(keys)
	playersLeftDown[keys.playerID] = true
	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)

	HeroLookAt(heroEntity, cursorPos)
	--heroEntity:StartGesture(ACT_DOTA_CAST_ABILITY_6)
end

function RubicksMagickMoveController:OnLeftUp(keys)
	playersLeftDown[keys.playerID] = false
end