
if MoveController == nil then
	MoveController = class({})
end

function MoveController:Precache(context)
	PrecacheResource("particle", "particles/ui_mouseactions/clicked_basemove.vpcf", context)
end

function MoveController:Init()	
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(MoveController, "OnMoveHeroesThink"), "MoveHeroesThink", 2)
	
	ListenToGameEvent("entity_killed", Dynamic_Wrap(MoveController, "OnEntityKilled"), self)

	CustomGameEventManager:RegisterListener("me_mm", Dynamic_Wrap(MoveController, "OnMouseMove"))
	CustomGameEventManager:RegisterListener("me_rd", Dynamic_Wrap(MoveController, "OnRightDown"))
	CustomGameEventManager:RegisterListener("me_ru", Dynamic_Wrap(MoveController, "OnRightUp"))
	CustomGameEventManager:RegisterListener("me_ld", Dynamic_Wrap(MoveController, "OnLeftDown"))
	CustomGameEventManager:RegisterListener("me_lu", Dynamic_Wrap(MoveController, "OnLeftUp"))

	Convars:RegisterCommand("+rm_stp",  function(...) return MoveController:StopMove(Convars:GetCommandClient()) end, "Stop move", 0)
end

THINK_PERIOD = 0.03
function MoveController:OnMoveHeroesThink()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local heroEntity = player:GetAssignedHero()
			local isAble = (heroEntity ~= nil) and (heroEntity:IsAlive()) and (not heroEntity:IsStunned()) and (not heroEntity:IsFrozen())
			local dontMoveWhileCasting = player.spellCast ~= nil and player.spellCast.dontMoveWhileCasting
			if isAble and not dontMoveWhileCasting and player.moveToPos ~= nil then
				local moveStep = heroEntity:GetIdealSpeed() * THINK_PERIOD
				if player.moveToClearPos ~= nil then
					MoveController:MoveTowardsClearPos(player, heroEntity, moveStep * 2)
				else
					MoveController:MoveTowardsMoveToPos(player, heroEntity, moveStep)
				end
			end
		end
	end
	return THINK_PERIOD
end

function MoveController:MoveTowardsClearPos(player, heroEntity, moveStep)
	local oldOrigin = heroEntity:GetAbsOrigin()
	local vector = player.moveToClearPos - oldOrigin
	local distance = #vector
	if distance < moveStep then
		heroEntity:SetAbsOrigin(player.moveToClearPos)
		player.moveToClearPos = nil
	else
		heroEntity:SetAbsOrigin(oldOrigin + (vector / distance) * moveStep)
	end
end

function MoveController:MoveTowardsMoveToPos(player, heroEntity, moveStep)
	local oldOrigin = heroEntity:GetAbsOrigin()
	local vector = player.moveToPos - oldOrigin
	local distance = #vector
	local to
	if distance < moveStep then
		to = player.moveToPos
		player.moveToPos = nil
		heroEntity:FadeGesture(ACT_DOTA_RUN)
		ParticleManager:DestroyParticle(player.moveToParticle, false)
	else
		to = oldOrigin + (vector / distance) * moveStep
	end
	if GridNav:IsTraversable(to) and not GridNav:IsBlocked(to) then
		heroEntity:SetAbsOrigin(to)
	else
		repeat
			local trees = GridNav:GetAllTreesAroundPoint(to, 1, true)
			local treePos = trees[1]:GetAbsOrigin()
			local offset = (to - treePos):Normalized() * 10
			offset.z = 0
			to = to + offset
		until GridNav:IsTraversable(to) and not GridNav:IsBlocked(to)
		player.moveToClearPos = to
	end
end

function MoveController:ShowMoveToParticle(player, pos)
    local PARTICLE_FILE = "particles/ui_mouseactions/clicked_basemove.vpcf"
    if player.moveToParticle ~= nil then
    	ParticleManager:DestroyParticle(player.moveToParticle, false)
    end
    player.moveToParticle = ParticleManager:CreateParticleForPlayer(PARTICLE_FILE, PATTACH_CUSTOMORIGIN, nil, player)
	ParticleManager:SetParticleControl(player.moveToParticle, 1, Vector(0, 255, 0))	-- green color
    ParticleManager:SetParticleControl(player.moveToParticle, 0, pos)
end


function MoveController:PlayerConnected(player)
	player.rightDown = false;
    player.leftDown = false;
end

function MoveController:OnEntityKilled(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	if killedUnit ~= nil and killedUnit:IsRealHero() then
		MoveController:StopMove(killedUnit:GetPlayerOwner())
	end
end

function MoveController:StopMove(player)
	if player ~= nil then
		player.moveToPos = nil
		player.moveToClearPos = nil
		local heroEntity = player:GetAssignedHero()
		if heroEntity ~= nil then
			heroEntity:FadeGesture(ACT_DOTA_RUN)
		end
	end
end

function MoveController:HeroLookAt(heroEntity, targetPos)
	if heroEntity ~= nil then
		targetPos.z = heroEntity:GetAbsOrigin().z
		local oldForward = heroEntity:GetForwardVector()
		local forward = targetPos - heroEntity:GetAbsOrigin()
		if #forward < 1 then 	-- prevent from zero-vector
			forward = oldForward 
		end
		heroEntity:SetForwardVector(forward)
	end
end

function MoveController:OnMouseMove(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local heroEntity = player:GetAssignedHero()
	local isAble = (heroEntity ~= nil) and (heroEntity:IsAlive()) and (not heroEntity:IsStunned()) and (not heroEntity:IsFrozen())
	if isAble then
		player.cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
		local dontMoveWhileCasting = player.spellCast ~= nil and player.spellCast.dontMoveWhileCasting
		if not dontMoveWhileCasting then
			MoveController:HeroLookAt(heroEntity, player.cursorPos)
		end
		if player.rightDown then
			local dontChangeGesture = player.spellCast ~= nil and player.spellCast.castingGesture ~= nil
			if player.moveToPos == nil and not dontChangeGesture and not dontMoveWhileCasting then
				heroEntity:StartGesture(ACT_DOTA_RUN)
			end
			player.moveToPos = player.cursorPos
			MoveController:ShowMoveToParticle(player, player.cursorPos)
		end
	end
end	


function MoveController:OnRightDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local heroEntity = player:GetAssignedHero()
	local isAble = (heroEntity ~= nil) and (heroEntity:IsAlive()) and (not heroEntity:IsStunned()) and (not heroEntity:IsFrozen())
	if isAble then
		player.rightDown = true
		player.cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
		local dontChangeGesture = player.spellCast ~= nil and player.spellCast.castingGesture ~= nil
		if player.moveToPos == nil and not dontChangeGesture and not dontMoveWhileCasting then
			heroEntity:StartGesture(ACT_DOTA_RUN)
		end
		player.moveToPos = player.cursorPos
		MoveController:HeroLookAt(heroEntity, player.cursorPos)
		MoveController:ShowMoveToParticle(player, player.cursorPos)
	end
end

function MoveController:OnRightUp(keys)
	PlayerResource:GetPlayer(keys.playerID).rightDown = false
end

function MoveController:OnLeftDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	local heroEntity = player:GetAssignedHero()
	local isAble = (heroEntity ~= nil) and (heroEntity:IsAlive()) and (not heroEntity:IsStunned()) and (not heroEntity:IsFrozen())
	if isAble then
		player.leftDown = true
		player.cursorPos = Vector(keys.worldX, keys.worldY, keys.worldZ)
		MoveController:HeroLookAt(heroEntity, player.cursorPos)
	end
end

function MoveController:OnLeftUp(keys)
	PlayerResource:GetPlayer(keys.playerID).leftDown = false
end