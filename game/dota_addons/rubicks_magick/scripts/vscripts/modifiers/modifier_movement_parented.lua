
if modifier_movement_parented == nil then
	modifier_movement_parented = class({})
end

function modifier_movement_parented:IsHidden()
	return true
end

function modifier_movement_parented:IsPermanent()
	return true
end

function modifier_movement_parented:RemoveOnDeath()
	return false
end

function modifier_movement_parented:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true
	} 
	return state
end