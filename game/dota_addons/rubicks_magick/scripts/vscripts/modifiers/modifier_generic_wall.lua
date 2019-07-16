
if modifier_generic_wall == nil then
	modifier_generic_wall = class({})
end

function modifier_generic_wall:IsHidden()
	return true
end

function modifier_generic_wall:CheckState()
	local state = {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true
	} 
	return state
end