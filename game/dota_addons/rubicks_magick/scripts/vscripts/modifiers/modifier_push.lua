local THINK_PERIOD = 0.01
local GRAVITY_VECTOR = Vector(0, 0, -400)
local GRAVITY_DELAY = 0.2

if modifier_push == nil then
	modifier_push = class({})
end

function modifier_push:IsDebuff()
	return true
end

function modifier_push:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true
	} 
	return state
end

function modifier_push:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
	return funcs
end

function modifier_push:GetOverrideAnimation(params)
	return ACT_DOTA_FLAIL
end

function modifier_push:OnCreated(kv)
	if IsServer() then
		self.velocity = Vector(0, 0, 0)
		self.acceleration = Vector(0, 0, 0)
		self:OnRefresh(kv)

		self:PlaceParentInAir()
		self:StartIntervalThink(THINK_PERIOD)
	end
end

function modifier_push:OnRefresh(kv)
	if IsServer() then
		self.velocity = self.velocity + Vector(kv.vel_x or 0.0, kv.vel_y or 0.0, kv.vel_z or 0.0)
		self.acceleration = self.acceleration + Vector(kv.acc_x or 0.0, kv.acc_y or 0.0, kv.acc_z or 0.0)

		if kv.delay_gravity == 1 then
			self:PostponeGravity()
		end
	end
end

function modifier_push:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		parent:SetAbsOrigin(GetGroundPosition(parent:GetAbsOrigin(), parent))
	end
end

function modifier_push:PostponeGravity()
	self.gravityStartTime = GameRules:GetGameTime() + GRAVITY_DELAY
end

function modifier_push:OnIntervalThink()
	if IsServer() then
		self:MovementUpdate(THINK_PERIOD) 
		if not self:IsParentInAir() then
			self:Destroy()
		end
	end
end

function modifier_push:PlaceParentInAir()
	local parent = self:GetParent()
	parent:SetAbsOrigin(parent:GetAbsOrigin() + Vector(0, 0, 20))
end

function modifier_push:MovementUpdate(dt)
	local parent = self:GetParent()
	local oldPosition = parent:GetAbsOrigin()

	local desiredPosition = oldPosition + self.velocity * dt
	self.velocity = self.velocity + self.acceleration * dt
	if self.gravityStartTime == nil or GameRules:GetGameTime() > self.gravityStartTime then
		self.velocity = self.velocity + GRAVITY_VECTOR * dt
	end
	
	FindClearSpaceForUnit(parent, desiredPosition, false)
	local newActualPosition = parent:GetAbsOrigin()
	newActualPosition.z = desiredPosition.z
	parent:SetAbsOrigin(newActualPosition)

	local desiredDeltaDistance = (desiredPosition - oldPosition):Length2D()
	local actualDeltaDistance = (newActualPosition - oldPosition):Length2D()
	if actualDeltaDistance < 0.5 * desiredDeltaDistance then
		self.velocity = Vector(0, 0, 0)
		self.acceleration = Vector(0, 0, 0)
	end
end

function modifier_push:IsParentInAir()
	local position = self:GetParent():GetAbsOrigin()
	return position.z > GetGroundHeight(position, parent)
end