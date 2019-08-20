require("libraries/timers")

LinkLuaModifier("modifier_frozen", "modifiers/modifier_frozen.lua", LUA_MODIFIER_MOTION_NONE)

if modifier_chill == nil then
	modifier_chill = class({})
end

local THINK_PERIOD = 0.1
local REDUCE_PER_SECOND = 15
local CHILL_FREEZE_POINT = 255
local REDUCE_PER_THINK = REDUCE_PER_SECOND * THINK_PERIOD
local CHILL_STATUS_EFFECT_STEPS = 7

function modifier_chill:IsHidden()
	return false
end

function modifier_chill:IsDebuff()
	return true
end

function modifier_chill:IsPermanent()
	return true
end

function modifier_chill:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_chill:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH
	}
	return funcs
end

function modifier_chill:OnDeath()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_chill:GetModifierMoveSpeedBonus_Percentage(params)
	return -90 * (self:GetStackCount() / CHILL_FREEZE_POINT)
end

function modifier_chill:GetStatusEffectName()
	local chilledFxNumber = self:GetStatusEffectNumber(self:GetStackCount())
	return "particles/modifier_status_fx/chilled/chilled".. tostring(chilledFxNumber) ..".vpcf"
end

function modifier_chill:OnCreated(kv)
	if IsServer() then
		self:StartIntervalThink(THINK_PERIOD)
	end
end

function modifier_chill:OnRefresh(kv)
	if IsServer() then
		print("Refresh", self)
	end
end

function modifier_chill:Enhance(value)
	if IsServer() then
		self:SetStackCount(self:GetStackCount() + value)
	end
end

function modifier_chill:OnIntervalThink()
	if IsServer() then
		self:SetStackCount(self:GetStackCount() - REDUCE_PER_THINK)
	end
end

function modifier_chill:OnStackCountChanged(oldStacks)
	if IsServer() then
		local stacks = self:GetStackCount()
		if stacks >= CHILL_FREEZE_POINT then
			self:GetParent():AddNewModifier(self:GetCaster(), nil, "modifier_frozen", { duration = 10.0 })
			self:Destroy()
		elseif stacks <= 0 then
			self:Destroy()
		elseif self:GetStatusEffectNumber(oldStacks) ~= self:GetStatusEffectNumber(stacks) and oldStacks ~= 0 then
			-- if oldStacks were 0 and stacks were X then the following code would cause Dota to create a new modifier and 
			-- call OnStackCountChanged on it with the same values oldStacks = 0 and stacks = X, so 
			-- it would basically be an infinite recursion.

			-- Forcing the modifier to be recreated to ensure GetStatusEffectName() call that's sensitive to stack count
			self:ScheduleRecreation()
		end
	end
end

function modifier_chill:ScheduleRecreation()
	if self.recreateTimer == nil then
		self.recreateTimer = Timers:CreateTimer(0.2, function()
			self.recreateTimer = nil
			local parent = self:GetParent()
			if not parent:IsAlive() then
				return
			end
			local newModifier = parent:AddNewModifier(self:GetCaster(), nil, "modifier_chill", {})
			newModifier:SetStackCount(self:GetStackCount())
			self:Destroy()
		end)
	end
end

function modifier_chill:OnDestroy()
	self:StartIntervalThink(-1)
	if self.recreateTimer ~= nil then
		Timers:RemoveTimer(self.recreateTimer)
	end
end

function modifier_chill:GetStatusEffectNumber(stacks)
	local number = math.ceil(stacks / CHILL_FREEZE_POINT * CHILL_STATUS_EFFECT_STEPS)
	number = math.min(number, CHILL_STATUS_EFFECT_STEPS)
	return number
end