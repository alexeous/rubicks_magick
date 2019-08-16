if Modifiers == nil then
    Modifiers = class({})
end

function Modifiers:ApplyWet(target, caster)
	if SelfShield:HasAnyResistanceTo(target, ELEMENT_WATER) or target:IsInvulnerable() then
		return false
	end

	local wasBurning = Modifiers:ExtinguishWithElement(target, ELEMENT_WATER)
	if not wasBurning and Modifiers:CanApplyModifier(target, ELEMENT_WATER) and not target:HasModifier("modifier_chill") then
		target:AddNewModifier(caster, nil, "modifier_wet", {})
	end
	return true
end

function Modifiers:ApplyChill(target, caster, power)
	if SelfShield:HasAnyResistanceTo(target, ELEMENT_COLD) or target:IsInvulnerable() then
		return false
	end

	local wasBurning = Modifiers:ExtinguishWithElement(target, ELEMENT_COLD)
	if not wasBurning and Modifiers:CanApplyModifier(target, ELEMENT_COLD) then
		local currentChillModifier = target:FindModifierByName("modifier_chill")
		if currentChillModifier ~= nil then
			currentChillModifier:Enhance(power)
		else
			target:AddNewModifier(caster, nil, "modifier_chill", {})
			target:SetModifierStackCount("modifier_chill", caster, power)
		end
	end
	return true
end

function Modifiers:ApplyBurn(target, caster)
	if SelfShield:HasAnyResistanceTo(target, ELEMENT_FIRE) or target:IsInvulnerable() then
		return false
	end

	local wasWetOrChilled = Modifiers:DryAndWarm(target)
	if not wasWetOrChilled and Modifiers:CanApplyModifier(target, ELEMENT_FIRE) then
		local currentBurnModifier = target:FindModifierByName("modifier_burn")
		if currentBurnModifier ~= nil then
			currentBurnModifier:Reapply()
		else
			target:AddNewModifier(caster, nil, "modifier_burn", {})
		end
	end
	return true
end

function Modifiers:CanApplyModifier(target, element)
	if target == nil then
		return false
	end
	if target.dryWarmExtinguishElement == nil or target.dryWarmExtinguishTime == nil then
		return true
	end
	local time = GameRules:GetGameTime()
	return not (target.dryWarmExtinguishElement == element and time - target.dryWarmExtinguishTime < DRY_WARM_EXTINGUISH_GUARD_DURATION)
end

function Modifiers:DryAndWarm(target)
	if target == nil or SelfShield:HasAnyResistanceTo(target, ELEMENT_FIRE) then
		return false
	end
	if target:HasModifier("modifier_wet") then
		target:RemoveModifierByName("modifier_wet")
		Modifiers:SetupDryWarmExtinguishGuard(target, ELEMENT_FIRE)
		return true
	elseif target:HasModifier("modifier_chill") then
		target:RemoveModifierByName("modifier_chill")
		Modifiers:SetupDryWarmExtinguishGuard(target, ELEMENT_FIRE)
		return true
	end
	return false
end

function Modifiers:ExtinguishWithElement(target, element)
	if target == nil or SelfShield:HasAnyResistanceTo(target, element) then
		return false
	end
	if target:HasModifier("modifier_burn") then
		target:RemoveModifierByName("modifier_burn")
		Modifiers:SetupDryWarmExtinguishGuard(target, element)
		return true
	end
	return false
end

function Modifiers:SetupDryWarmExtinguishGuard(target, element)
	target.dryWarmExtinguishElement = element
	target.dryWarmExtinguishTime = GameRules:GetGameTime()
end