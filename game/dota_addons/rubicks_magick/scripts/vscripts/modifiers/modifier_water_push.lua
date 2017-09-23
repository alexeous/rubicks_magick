require("libraries/physics")

if modifier_water_push == nil then
	modifier_water_push = class({})
end

function modifier_water_push:IsDebuff()
	return true
end

function modifier_water_push:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		parent:SetPhysicsVelocity(Vector(0, 0, 0))
		parent:SetPhysicsAcceleration(Vector(0, 0, 0))
		--parent:SetAbsOrigin(GetGroundPosition(parent:GetAbsOrigin(), parent))
		FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), false)
		if self.wasLockedToGround then
			parent:SetGroundBehavior(PHYSICS_GROUND_LOCK)
		end
	end
end

function modifier_water_push:OnCreated(kv)
	if IsServer() then
		local parent = self:GetParent()
		parent:SetAbsOrigin(parent:GetAbsOrigin() + Vector(0, 0, 5))

		if not IsPhysicsUnit(parent) then
			Physics:Unit(parent)
		else
			self.wasLockedToGround = (parent:GetGroundBehavior() == PHYSICS_GROUND_LOCK)
		end
		local velocity = Vector(kv.vel_x or 0.0, kv.vel_y or 0.0, kv.vel_z or 0.0)
		local acceleration = Vector(kv.acc_x or 0.0, kv.acc_y or 0.0, kv.acc_z or 0.0)
		local gravity = Vector(0, 0, -900)
		parent:AddPhysicsVelocity(velocity)
		parent:AddPhysicsAcceleration(acceleration + gravity)

		self.destruction = false
		self:StartIntervalThink(PHYSICS_THINK)
	end
end

function modifier_water_push:Enhance(velocity, acceleration)
	if IsServer() then
		local parent = self:GetParent()
		if velocity ~= nil then
			parent:AddPhysicsVelocity(velocity)
		end
		if acceleration ~= nil then
			parent:AddPhysicsAcceleration(acceleration)
		end

		self.destruction = false
		self:StartIntervalThink(PHYSICS_THINK)
	end
end

function modifier_water_push:OnIntervalThink()
	if IsServer() then
		if self.destruction then
			self:Destroy()
		else
			local parent = self:GetParent()
			local parentPos = parent:GetAbsOrigin()
			if parentPos.z <= GetGroundHeight(parentPos, parent) then
				self.destruction = true
				self:StartIntervalThink(0.3)
			end
		end
	end
end


function modifier_water_push:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true
	} 
	return state
end

function modifier_water_push:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
	return funcs
end

function modifier_water_push:GetOverrideAnimation(params)
	return ACT_DOTA_FLAIL
end