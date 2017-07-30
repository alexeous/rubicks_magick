if OmniElementSprays == nil then
	OmniElementSprays = class({})
end

function OmniElementSprays:Precache(context)
	PrecacheResource("particle_folder", "particles/omni_sprays/omni_steam_spray", context)
	PrecacheResource("particle_folder", "particles/omni_sprays/omni_water_spray", context)
	PrecacheResource("particle_folder", "particles/omni_sprays/omni_fire_spray", context)
	PrecacheResource("particle_folder", "particles/omni_sprays/omni_cold_spray", context)
end

function OmniElementSprays:PlayerConnected(player)

end


function OmniElementSprays:OmniSteamSpraySpell(player, modifierElement)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.8,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.3,
		castingGestureTranslate = "am_blink"
	}
	Spells:StartCasting(player, spellCastTable)

	local isWet = false
	local radius = OMNI_SPELLS_RADIUSES[1]
	local damage = 70
	if modifierElement == ELEMENT_WATER then
		isWet = true
		damage = 100
		radius = OMNI_SPELLS_RADIUSES[2]
	elseif modifierElement == ELEMENT_FIRE then
		damage = 150
		radius = OMNI_SPELLS_RADIUSES[2]
	end

	local heroEntity = player:GetAssignedHero()
	OmniElementSprays:OmniSteamSpray(heroEntity, heroEntity:GetAbsOrigin(), radius, true, damage, isWet)
end

function OmniElementSprays:OmniWaterSpraySpell(player, power)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.8,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.3,
		castingGestureTranslate = "am_blink"
	}
	Spells:StartCasting(player, spellCastTable)

	local radius = OMNI_SPELLS_RADIUSES[power]
	local heroEntity = player:GetAssignedHero()
	OmniElementSprays:OmniWaterSpray(heroEntity, heroEntity:GetAbsOrigin(), radius, true, true)
end

function OmniElementSprays:OmniFireSpraySpell(player, power)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.8,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.3,
		castingGestureTranslate = "am_blink"
	}
	Spells:StartCasting(player, spellCastTable)

	local radius = OMNI_SPELLS_RADIUSES[power]
	local damage = 60 * power
	local heroEntity = player:GetAssignedHero()
	OmniElementSprays:OmniFireSpray(heroEntity, heroEntity:GetAbsOrigin(), radius, true, damage)
end

function OmniElementSprays:OmniColdSpraySpell(player, power)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.8,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.3,
		castingGestureTranslate = "am_blink"
	}
	Spells:StartCasting(player, spellCastTable)

	local radius = OMNI_SPELLS_RADIUSES[power]
	local damage = 40 * power
	local heroEntity = player:GetAssignedHero()
	OmniElementSprays:OmniColdSpray(heroEntity, heroEntity:GetAbsOrigin(), radius, true, damage)
end


function OmniElementSprays:OmniSteamSpray(caster, position, radius, isSelfCast, damage, isWet)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_WATER, damage / 2, isSelfCast, isWet, 1.0)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_FIRE, damage / 2, isSelfCast, false, 1.0)

	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_steam_spray/omni_steam_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 40
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(1, radius - 100, (isWet and 1 or 0)))
end

function OmniElementSprays:OmniWaterSpray(caster, position, radius, isSelfCast, doPush)
	local canPushCaster = isSelfCast and Spells:ResistanceLevelTo(caster, ELEMENT_WATER) < 2
	
	local units = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,
	    DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)
	for _, unit in pairs(units) do
		if not (unit == caster and isSelfCast) then
			Spells:ApplyElementDamage(unit, caster, ELEMENT_WATER, 1, true, 1.0)
			if doPush then
				if Spells:ResistanceLevelTo(unit, ELEMENT_WATER) < 2 then
					OmniElementSprays:Push(unit, caster, position, radius)
			    elseif canPushCaster then
			    	OmniElementSprays:Push(caster, caster, unit:GetAbsOrigin(), radius)
				end
	    	end
		end
	end

	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_water_spray/omni_water_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 40
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius / 250 + 0.2, radius, 0))
end

function OmniElementSprays:Push(target, caster, center, distance)
	local distanceToTarget = (target:GetAbsOrigin() - center):Length2D()
	local multiplier = math.pow(0.5, Spells:ResistanceLevelTo(target, ELEMENT_EARTH))
	local knockbackProperties = {
		center_x = center.x,
		center_y = center.y,
		center_z = center.z,
		duration = 0.35,
		knockback_duration = 0.35,
		knockback_height = 40,
		knockback_distance = (distance + 100 - distanceToTarget) * multiplier
	}
	target:AddNewModifier(caster, nil, "modifier_knockback", knockbackProperties)
end


function OmniElementSprays:OmniFireSpray(caster, position, radius, isSelfCast, damage)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_FIRE, damage, isSelfCast, true)

	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_fire_spray/omni_fire_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 20
	radius = radius - 100
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius / 250 + 0.2, radius, 0))
end

function OmniElementSprays:OmniColdSpray(caster, position, radius, isSelfCast, damage)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_COLD, damage, isSelfCast, true)

	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_cold_spray/omni_cold_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 40
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius / 250 + 0.2, radius, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius - 50, 1, 0))
end