
if RubicksMagickMoveController == nil then
	RubicksMagickMoveController = class({})
end

playersRightDown = {}
playersLeftDown = {}
playersMoveTo = {}
moveToParticleIndices = {}



function RubicksMagickMoveController:Init()
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(RubicksMagickMoveController, "OnMoveHeroesThink"), "MoveHeroesThink", 2)
	
	CustomGameEventManager:RegisterListener("me_mm", Dynamic_Wrap(RubicksMagickMoveController, "OnMouseMove"))
	CustomGameEventManager:RegisterListener("me_rd", Dynamic_Wrap(RubicksMagickMoveController, "OnRightDown"))
	CustomGameEventManager:RegisterListener("me_ru", Dynamic_Wrap(RubicksMagickMoveController, "OnRightUp"))
	CustomGameEventManager:RegisterListener("me_ld", Dynamic_Wrap(RubicksMagickMoveController, "OnLeftDown"))
	CustomGameEventManager:RegisterListener("me_lu", Dynamic_Wrap(RubicksMagickMoveController, "OnLeftUp"))
end

function RubicksMagickMoveController:OnMoveHeroesThink()
	local MOVE_PER_THINK = 11.0
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		if playersMoveTo[playerID] ~= nil then
			local player = PlayerResource:GetPlayer(playerID)
			if player ~= nil then
				local heroEntity = player:GetAssignedHero()
				if heroEntity ~= nil then
					local moveFrom = heroEntity:GetAbsOrigin()
					local vec = playersMoveTo[playerID] - moveFrom
					local distance = #vec
					local newOrigin
					if distance < MOVE_PER_THINK then
						newOrigin = moveFrom + vec
						heroEntity:FadeGesture(ACT_DOTA_RUN)
						playersMoveTo[playerID] = nil
		    			ParticleManager:DestroyParticle(moveToParticleIndices[playerID], false)
					else
						newOrigin = moveFrom + (vec / distance) * MOVE_PER_THINK
					end
					FindClearSpaceForUnit(heroEntity, newOrigin, false)
				end
			end
		end
	end
	return 0.03
end

function RubicksMagickMoveController:ShowMoveToParticle(playerID, pos)
    local player = PlayerResource:GetPlayer(playerID)
    local PARTICLE_FILE = "particles/ui_mouseactions/clicked_basemove.vpcf"
    if moveToParticleIndices[playerID] ~= nil then
    	ParticleManager:DestroyParticle(moveToParticleIndices[playerID], false)
    end
    moveToParticleIndices[playerID] = ParticleManager:CreateParticleForPlayer(PARTICLE_FILE, PATTACH_CUSTOMORIGIN, nil, player)
	ParticleManager:SetParticleControl(moveToParticleIndices[playerID], 1, Vector(0, 255, 0))	-- green color
    ParticleManager:SetParticleControl(moveToParticleIndices[playerID], 0, pos)
end


function RubicksMagickMoveController:PlayerConnected(playerID)
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
	if playersLeftDown[keys.playerID] and heroEntity ~= nil then
		HeroLookAt(heroEntity, cursorPos)
	end
	if playersRightDown[keys.playerID] and heroEntity ~= nil then
		HeroLookAt(heroEntity, cursorPos)
		if playersMoveTo[keys.playerID] == nil then
			heroEntity:StartGesture(ACT_DOTA_RUN)
		end
		playersMoveTo[keys.playerID] = cursorPos
		RubicksMagickMoveController:ShowMoveToParticle(keys.playerID, cursorPos)
	end
end	


function RubicksMagickMoveController:OnRightDown(keys)
	playersRightDown[keys.playerID] = true

	local heroEntity = PlayerResource:GetPlayer(keys.playerID):GetAssignedHero()
	if heroEntity ~= nil then
		local cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
		playersMoveTo[keys.playerID] = cursorPos
		RubicksMagickMoveController:ShowMoveToParticle(keys.playerID, cursorPos)

		HeroLookAt(heroEntity, cursorPos)
		heroEntity:StartGesture(ACT_DOTA_RUN)
	end
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