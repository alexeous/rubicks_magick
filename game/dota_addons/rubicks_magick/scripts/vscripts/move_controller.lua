require("libraries/physics")

if MoveController == nil then
	MoveController = class({})
end

function MoveController:Precache(context)
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

THINK_PERIOD = 0.03
function MoveController:OnMoveHeroesThink()
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local hero = player:GetAssignedHero()
			if hero ~= nil then
				MoveController:OnMoveHeroThink(player, hero)
			end
		end
	end
	return THINK_PERIOD
end

function MoveController:OnMoveHeroThink(player, hero)
	if not IsPhysicsUnit(hero) then
		Physics:Unit(hero)
		hero:SetGroundBehavior(PHYSICS_GROUND_LOCK)
	end

	local isAble = hero:IsAlive() and not hero:IsStunned() and not hero:IsFrozen()
	if not isAble then
		if player.moveToPos ~= nil then
			MoveController:StopMove(player)
		end
		return
	end

	local dontMoveWhileCasting = player.spellCast ~= nil and player.spellCast.dontMoveWhileCasting
	if dontMoveWhileCasting then
		hero:SetPhysicsVelocity(Vector(0, 0, 0))
		return
	end
	
	MoveController:UpdateRotation(player, hero)
	if player.moveToPos ~= nil then
		local origin = hero:GetAbsOrigin()
		local vec = player.moveToPos - origin
		if vec:Length2D() > 20 then
			hero:SetPhysicsVelocity(vec:Normalized() * hero:GetIdealSpeed())
		else
			MoveController:StopMove(player)
		end
	end
end

function MoveController:UpdateRotation(player, hero)
	if player.cursorPos ~= nil then
		MoveController:HeroLookAt(hero, player.cursorPos)
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
	player.moveToKeyDown = false
end

function MoveController:OnEntityKilled(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	if killedUnit ~= nil and killedUnit:IsRealHero() then
		MoveController:StopMove(killedUnit:GetPlayerOwner())
	end
end

function MoveController:OnStopMoveKeyDown(keys)
	local player = PlayerResource:GetPlayer(keys.playerID)
	MoveController:StopMove(player)
end

function MoveController:StopMove(player, preserveMoveTargetPos)
	if player ~= nil then
		if not preserveMoveTargetPos then
			player.moveToPos = nil
		end
		local hero = player:GetAssignedHero()
		if hero ~= nil then
			hero:SetPhysicsVelocity(Vector(0, 0, 0))
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
	local hero = player:GetAssignedHero()
	local isAble = (hero ~= nil) and (hero:IsAlive()) and (not hero:IsStunned()) and (not hero:IsFrozen())
	if isAble then
		local dontChangeGesture = player.spellCast ~= nil and player.spellCast.castingGesture ~= nil
		local dontMoveWhileCasting = player.spellCast ~= nil and player.spellCast.dontMoveWhileCasting
		if player.moveToPos == nil and not dontChangeGesture and not dontMoveWhileCasting then
			hero:StartGesture(ACT_DOTA_RUN)
		end
		player.moveToPos = player.cursorPos
		MoveController:ShowMoveToParticle(player, player.cursorPos)
	end
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
	PlayerResource:GetPlayer(keys.playerID).moveToKeyDown = false
end