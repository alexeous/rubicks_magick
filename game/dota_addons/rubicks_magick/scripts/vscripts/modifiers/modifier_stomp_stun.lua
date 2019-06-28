
if modifier_stomp_stun == nil then
	modifier_stomp_stun = class({})
end

function modifier_stomp_stun:IsHidden()
	return false
end

function modifier_stomp_stun:IsDebuff()
	return true
end

function modifier_stomp_stun:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
	return funcs
end

function modifier_stomp_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true
	} 
	return state
end

function modifier_stomp_stun:GetOverrideAnimation(params)
	return ACT_DOTA_DISABLED
end