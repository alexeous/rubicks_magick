local HP_THINK_PERIOD = 0.02

if HP == nil then
    HP = class({})
    HP.manipulations = {}
end

function HP:Init()
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(HP, "OnHPThink"), "OnHPThink", 2)
end

function HP:OnHPThink()
	-- There might be events reacting on entity killed or smth like that that perform damage or heal applying
	-- thus causing changes to HP.manipulations. We ensure that any health change infos will be
    -- stored in another table, not the one we are processing right now to prevent its corruption
    local manipulations = HP.manipulations
    HP.manipulations = {}
    for target, allTargetInfos in pairs(manipulations) do
        for source, info in pairs(allTargetInfos) do
            local deltaHP = info.deltaHP
            if target.isPlaceable then
                ApplyDamage({ victim = target, attacker = source, damage = 1, damage_type = DAMAGE_TYPE_PURE })
            elseif deltaHP > 0 then
                deltaHP = math.min(deltaHP, target:GetMaxHealth() - target:GetHealth())
                target:Heal(deltaHP, source)
                SendOverheadEventMessage(target, OVERHEAD_ALERT_HEAL, target, deltaHP, target)
            else
                ApplyDamage({ victim = target, attacker = source, damage = -deltaHP, damage_type = DAMAGE_TYPE_PURE })
            end
        end

        if target:IsAlive() then
            for source, info in pairs(allTargetInfos) do
                for _, m in pairs(info.applyModifiers) do
                    if m.element == ELEMENT_WATER then
                        Modifiers:ApplyWet(target, source)
                    elseif m.element == ELEMENT_COLD then
                        Modifiers:ApplyChill(target, source, m.damage)
                    elseif m.element == ELEMENT_FIRE then
                        Modifiers:ApplyBurn(target, source)
                    end
                end
            end
        end
    end

    return HP_THINK_PERIOD
end

function HP:ApplyElement(target, caster, element, value, ignoreShields, dontApplyModifiers)
    if target:IsInvulnerable() then
		return false
	end

    value = HP:ResolveValue(value, target)
    if not ignoreShields then
        value = HP:GetDamageAfterShields(target, value, element)
    end

    if target:HasModifier("modifier_wet") and (element == ELEMENT_LIGHTNING or element == ELEMENT_COLD) then
        value = value * 2
        if target.wetRemoveTimer == nil then
            target.wetRemoveTimer = Timers:CreateTimer(0.4, function() 
                target.wetRemoveTimer = nil
                target:RemoveModifierByName("modifier_wet")
            end)
        end
    end

    if value < 0.5 then
        return false
    end

    local deltaHP = (element ~= ELEMENT_LIFE) and -value or value
    local applyModifier = nil
    if not dontApplyModifiers and (element == ELEMENT_WATER or element == ELEMENT_COLD or element == ELEMENT_FIRE) then
        applyModifier = { damage = value, element = element }
    end
    HP:DoManipulation(target, caster, deltaHP, applyModifier)

    return true
end

function HP:ApplyElementAoE(center, radius, caster, element, value, ignoreCaster)
    local affectedAnyone = false
	local targets = Util:FindUnitsInRadius(center, radius)
	for _, target in pairs(targets) do
		if not (target == caster and ignoreCaster) then
			local affected = HP:ApplyElement(target, caster, element, value)
			affectedAnyone = affectedAnyone or affected
		end
	end
	return affectedAnyone
end

function HP:GetDamageAfterShields(target, value, element)
    if target.shieldElements == nil then
        return value
    end

    local function reduceValue(n) value = math.max(0, value - (0.5 * value) * n) end
    local function any01(e) return SelfShield:HasAnyResistanceTo(target, e) and 1 or 0 end

    reduceValue(SelfShield:ResistanceLevelTo(target, element))
    if element == PSEUDO_ELEMENT_STEAM then
        reduceValue(any01(ELEMENT_WATER) + any01(ELEMENT_FIRE))
    elseif element == PSEUDO_ELEMENT_ICE then
        reduceValue(SelfShield:ResistanceLevelTo(target, ELEMENT_EARTH))
        reduceValue(any01(ELEMENT_WATER) + any01(ELEMENT_COLD))
    end
    
	return value
end

function HP:DoManipulation(target, caster, deltaHP, applyModifier)
    local manip = HP:PrepareManipulation(target, caster)
    manip.deltaHP = manip.deltaHP + deltaHP
    if applyModifier ~= nil then
        table.insert(manip.applyModifiers, applyModifier)
    end
end

function HP:PrepareManipulation(target, caster)
    if HP.manipulations[target] == nil then
        HP.manipulations[target] = {}
    end
    if HP.manipulations[target][caster] == nil then
        HP.manipulations[target][caster] = { deltaHP = 0, applyModifiers = {} }
    end
    return HP.manipulations[target][caster]
end

function HP:ResolveValue(value, target)
	local t = type(value)
	if t == "number" then
		return value
	elseif t == "function" then
		return value(target)
	end
    return 0
end

function HP:MakeReciprocalApplying(initialValue)
    local hitCounts = {}
    return function(target)
        local count = (hitCounts[target] or 0) + 1
        hitCounts[target] = count
        return initialValue / count
    end
end

function HP:MakeSharedApplyingCurried(value)
    local counters = {}
    return function(applyingNumber)
        return function(target)
            local counter = counters[target] or 0
            if applyingNumber > counter then
                counters[target] = applyingNumber
                return value
            else
                return 0
            end
        end
    end
end