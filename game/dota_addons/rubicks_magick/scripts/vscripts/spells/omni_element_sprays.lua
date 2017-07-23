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


function OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, damage, isWet)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_WATER, damage / 2, ignoreCaster, isWet, 1.0)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_FIRE, damage / 2, ignoreCaster, false, 1.0)

	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_steam_spray/omni_steam_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 40
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(1, radius - 100, (isWet and 1 or 0)))
end

function OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, doPush, canPushCaster)
	canPushCaster = canPushCaster and not Spells:IsResistantTo(caster, ELEMENT_WATER)

	local knockbackProperties = {
        center_x = position.x,
        center_y = position.y,
        center_z = position.z,
        duration = 0.35,
        knockback_duration = 0.35,
        knockback_height = 40
    }
	local units = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,
	    DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)
	for _, unit in pairs(units) do
		if not (unit == caster and ignoreCaster) then
			if Spells:IsResistantTo(unit, ELEMENT_WATER) then
				if (unit.shieldElements[1] == ELEMENT_WATER) and (unit.shieldElements[2] == ELEMENT_WATER) and canPushCaster then
					local unitPos = unit:GetAbsOrigin()
					local distance = (unitPos - caster:GetAbsOrigin()):Length2D()
					local knockbackPropertiesSelf = {
				        center_x = unitPos.x,
				        center_y = unitPos.y,
				        center_z = unitPos.z,
				        duration = 0.35,
				        knockback_duration = 0.35,
				        knockback_height = 40,
				        knockback_distance = radius + 100 - distance
				    }	
		    		caster:AddNewModifier(caster, nil, "modifier_knockback", knockbackPropertiesSelf)						
				end
			else
				Spells:ApplyElementDamage(unit, caster, ELEMENT_WATER, 1, true)
				local distance = (position - unit:GetAbsOrigin()):Length2D()
				local multiplier = 1
				if unit.shieldElements ~= nil then
					if unit.shieldElements[1] == ELEMENT_EARTH then  multiplier = multiplier / 2  end
					if unit.shieldElements[2] == ELEMENT_EARTH then  multiplier = multiplier / 2  end
				end
				knockbackProperties.knockback_distance = (radius + 100 - distance) * multiplier
	    		unit:AddNewModifier(caster, nil, "modifier_knockback", knockbackProperties)
	    	end
		end
	end
	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_water_spray/omni_water_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 40
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius / 250 + 0.2, radius, 0))
end

function OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, damage)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_FIRE, damage, ignoreCaster, true)

	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_fire_spray/omni_fire_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 20
	radius = radius - 100
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius / 250 + 0.2, radius, 0))
end

function OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, damage)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_COLD, damage, ignoreCaster, true)

	local particle = ParticleManager:CreateParticle("particles/omni_sprays/omni_cold_spray/omni_cold_spray.vpcf", PATTACH_CUSTOMORIGIN, nil)
	position.z = position.z + 40
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius / 250 + 0.2, radius, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius - 50, 1, 0))
end