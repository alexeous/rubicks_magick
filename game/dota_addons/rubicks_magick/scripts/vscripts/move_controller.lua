require("libraries/timers")
require("libraries/physics")

if MoveController == nil then
	MoveController = class({})
end

local THINK_PERIOD = 0.01

function MoveController:Precache(context)
	LinkLuaModifier("modifier_movement_dummy", "modifiers/modifier_movement_dummy.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_movement_parented", "modifiers/modifier_movement_parented.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle", "particles/ui_mouseactions/clicked_basemove.vpcf", context)
end

function MoveController:Init()	
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(MoveController, "OnMoveHeroesThink"), "MoveHeroesThink", 2)	
	ListenToGameEvent("entity_killed", Dynamic_Wrap(MoveController, "OnEntityKilled"), self)
	CustomGameEventManager:RegisterListener("rm_mouse_cycle", Dynamic_Wrap(MoveController, "OnMouseCycle"))
	CustomGameEventManager:RegisterListener("rm_stop_move", Dynamic_Wrap(MoveController, "OnStopMoveKeyDown"))
	CustomGameEventManager:RegisterListener("rm_move_to_down", Dynamic_Wrap(MoveController, "OnMoveToKeyDown"))
	CustomGameEventManager:RegisterListener("rm_move_to_up", Dynamic_Wrap(MoveController, "OnMoveToKeyUp"))
end


function MoveController:PlayerConnected(player)
	player.moveToKeyDown = false
	player.stoppedMovement = true
end

function MoveController:OnMoveHeroesThink()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local hero = player:GetAssignedHero()
			if hero ~= nil then
				MoveController:ThinkHeroMove(player, hero)
			end
		end
	end
	return THINK_PERIOD
end

function MoveController:OnEntityKilled(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	if killedUnit ~= nil and killedUnit:IsRealHero() then
		MoveController:OnHeroKilled(killedUnit)
	end
end

function MoveController:OnHeroKilled(hero)
	MoveController:StopMove(hero:GetPlayerOwner())
	Util:DoOnceTrue(
		function() return hero:IsAlive() end, 
		function() MoveController:SetHeroAndMoveParentAtSamePositions(hero) end
	)
end

function MoveController:OnStopMoveKeyDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	MoveController:StopMove(player)
end

function MoveController:OnMouseCycle(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	player.cursorPos = Vector(keys.x, keys.y, keys.z)
	if player.moveToKeyDown then
		MoveController:MoveToCursorCommand(player)
	end
end

function MoveController:OnMoveToKeyDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	player.moveToKeyDown = true
	MoveController:MoveToCursorCommand(player)

	local hero = player:GetAssignedHero()
	if hero ~= nil and hero:IsAlive() and hero:IsFrozen() then 
		hero:FindModifierByName("modifier_frozen"):ReleaseProgress()
	end
end

function MoveController:OnMoveToKeyUp(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	player.moveToKeyDown = false
end

function MoveController:ThinkHeroMove(player, hero)
	local isAble = hero:IsAlive() and not hero:IsStunned() and not hero:IsFrozen()
	if not isAble then
		if player.moveToPos ~= nil then
			MoveController:StopMove(player)
		end
		return
	end
	
	MoveController:UpdateRotation(player, hero)
	if player.moveToPos ~= nil then
		if player.callMoveToPositionASAP or player.stoppedMovement then
			player.callMoveToPositionASAP = false
			MoveController:ContinueMoveToPosition(player)
		end

		local origin = hero:GetAbsOrigin()
		local vec = player.moveToPos - origin
		if vec:Length2D() < 20 then
			MoveController:StopMove(player)
		end
	end
end

function MoveController:CreateMoveParent(player, hero)
	local moveParent = Util:CreateDummyWithoutModifier(hero:GetAbsOrigin(), hero)
	moveParent:AddNewModifier(moveParent, nil, "modifier_movement_dummy", {})
	moveParent:SetControllableByPlayer(player:GetPlayerID(), true) -- without this line there is a lag after MoveToPosition call
	moveParent:SetHullRadius(hero:GetHullRadius())
	moveParent:SetBaseMoveSpeed(hero:GetIdealSpeed())

	hero:SetParent(moveParent, nil)
	MoveController:AdaptHeroForMoveParentUsage(hero)
end

function MoveController:AdaptHeroForMoveParentUsage(hero)
	hero:AddNewModifier(hero, nil, "modifier_movement_parented", {})

	hero.OldGetAbsOrigin = hero.GetAbsOrigin
	hero.GetAbsOrigin = function(self)
		return self:GetMoveParent():GetAbsOrigin()
	end

	hero.angles = hero:GetAngles()
	hero.OldGetAngles = hero.GetAngles
	hero.GetAngles = function(self)
		return self.angles
	end
	hero.OldGetAnglesAsVector = hero.GetAnglesAsVector
	hero.GetAnglesAsVector = function(self)
		return Vector(self.angles.x, self.angles.y, self.angles.z)
	end
	hero.OldGetForwardVector = hero.GetForwardVector
	hero.GetForwardVector = function(self)
		return RotatePosition(Vector(0, 0, 0), self:GetAngles(), Vector(1, 0, 0))
	end

	hero.OldSetAbsOrigin = hero.SetAbsOrigin
	hero.SetAbsOrigin = function(self, newOrigin)
		self:GetMoveParent():SetAbsOrigin(newOrigin)
	end
	hero.OldSetAngles = hero.SetAngles
	hero.SetAngles = function(self, pitch, yaw, roll)
		self.angles = QAngle(pitch, yaw, roll)
		self:OldSetAngles(pitch, yaw, roll)
	end
	hero.OldSetForwardVector = hero.SetForwardVector
	hero.SetForwardVector = function(self, newForward)
		self:SetAngles(QAngle(0, math.deg(math.atan2(newForward.y, newForward.x)), 0))
	end
end

function MoveController:SetHeroAndMoveParentAtSamePositions(hero)
	if hero:GetMoveParent() == nil then
		return
	end
	local pos = hero:OldGetAbsOrigin()
	hero:GetMoveParent():SetAbsOrigin(pos)
	hero:OldSetAbsOrigin(pos)

	hero:RemoveModifierByName("modifier_movement_parented")		-- without these 2 lines the hero and
	hero:AddNewModifier(hero, nil, "modifier_movement_parented", {})	-- the move parent get stuck
end

function MoveController:UpdateRotation(player, hero)
	if player.cursorPos ~= nil then
		MoveController:HeroLookAt(hero, player.cursorPos)
	end
end

function MoveController:StopMove(player, preserveMoveTargetPos)
	if player ~= nil then
		player.stoppedMovement = true
		player.callMoveToPositionASAP = false
		if not preserveMoveTargetPos then
			player.moveToPos = nil
		end
		local hero = player:GetAssignedHero()
		if hero ~= nil then
			hero:GetMoveParent():MoveToPosition(hero:GetAbsOrigin())
			hero:FadeGesture(ACT_DOTA_RUN)
		end
	end
end

function MoveController:HeroLookAt(hero, targetPos)
	if hero ~= nil then
		local yaw = hero:GetAngles().y
		local targetYaw = VectorToAngles(targetPos - hero:GetAbsOrigin()).y

		local player = hero:GetPlayerOwner()
		if player ~= nil and player.spellCast ~= nil and player.spellCast.turnDegsPerSec ~= nil then
			local clampValue = player.spellCast.turnDegsPerSec * THINK_PERIOD
			local diff = AngleDiff(targetYaw, yaw)
			targetYaw = yaw + math.max(-clampValue, math.min(diff, clampValue))
		end

		hero:SetAngles(0, targetYaw, 0)
	end
end

function MoveController:MoveToCursorCommand(player)
	player.moveToPos = player.cursorPos
	MoveController:ShowMoveToParticle(player, player.cursorPos)
	MoveController:ContinueMoveToPosition(player)
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

function MoveController:ContinueMoveToPosition(player)
	if player.moveToPos == nil then
		return
	end

	player.callMoveToPositionASAP = false

	local hero = player:GetAssignedHero()	
	local spellCast = player.spellCast

	local inImmovableCast = spellCast ~= nil and spellCast.dontMoveWhileCasting
	if hero == nil or not hero:IsAlive() or hero:IsStunned() or hero:IsFrozen() or inImmovableCast then
		player.callMoveToPositionASAP = true
		return
	end

	local playingCastingGesture = spellCast ~= nil and spellCast.castingGesture ~= nil
	if player.stoppedMovement and not playingCastingGesture then
		hero:StartGesture(ACT_DOTA_RUN)
	end

	player.stoppedMovement = false

	if hero:GetMoveParent() == nil then
		MoveController:CreateMoveParent(player, hero)
	end
	hero:GetMoveParent():MoveToPosition(player.moveToPos)
end