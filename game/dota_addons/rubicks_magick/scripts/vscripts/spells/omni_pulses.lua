if OmniPulses == nil then
	OmniPulses = class({})
end

function OmniPulses:Precache(context)
	PrecacheResource("particle_folder", "particles/omni_pulses/omni_death_pulse", context)
	PrecacheResource("particle_folder", "particles/omni_pulses/omni_life_pulse", context)
end

function OmniPulses:PlayerConnected(player)
end


function OmniPulses:OmniLifePulseSpell(player, modifierElements)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.8,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.6,
		castingGestureTranslate = "purification"
	}
	Spells:StartCasting(player, spellCastTable)

	local heroEntity = player:GetAssignedHero()
	OmniPulses:OmniLifePulse(heroEntity, heroEntity:GetAbsOrigin(), true, modifierElements, 1.0)
end

function OmniPulses:OmniDeathPulseSpell(player, modifierElements)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.8,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.0,
		castingGestureTranslate = "shadowraze"
	}
	Spells:StartCasting(player, spellCastTable)

	local heroEntity = player:GetAssignedHero()
	OmniPulses:OmniDeathPulse(heroEntity, heroEntity:GetAbsOrigin(), true, modifierElements, 1.0)
end

function OmniPulses:OmniLifePulse(caster, position, ignoreCaster, modifierElements, factor)
	local radius = OMNI_SPELLS_RADIUSES[1] * factor
	local heal = 100 * factor
	local modifierDamage = 0

	local lifeInd = table.indexOf(modifierElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		table.remove(modifierElements, lifeInd)

		radius = OMNI_SPELLS_RADIUSES[2] * factor
		heal = 160 * factor
		if modifierElements[1] == ELEMENT_FIRE then
			modifierDamage = 20 * factor
			OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, modifierDamage)
		elseif modifierElements[1] == ELEMENT_COLD then
			modifierDamage = 20 * factor
			OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, modifierDamage)
		elseif modifierElements[1] == ELEMENT_WATER then
			OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false, false)
		end
	else
		local fireInd = table.indexOf(modifierElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(modifierElements, fireInd)
			
			if modifierElements[1] == ELEMENT_WATER then
				modifierDamage = 50 * factor
				OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, modifierDamage, false)
			else
				modifierDamage = 20 * factor
				if modifierElements[1] == ELEMENT_FIRE then
					modifierDamage = 40 * factor
				end
				OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, modifierDamage)
			end
		else
			local waterInd = table.indexOf(modifierElements, ELEMENT_WATER)
			if waterInd ~= nil then
				table.remove(modifierElements, waterInd)

				local doPush = false
				if modifierElements[1] == ELEMENT_WATER then  doPush = true  end
				OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, doPush)
			else
				local coldInd = table.indexOf(modifierElements, ELEMENT_COLD)
				if coldInd ~= nil then
					table.remove(modifierElements, coldInd)

					modifierDamage = 20 * factor
					if modifierElements[1] == ELEMENT_COLD then  modifierDamage = 40 * factor  end
					OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, modifierDamage)
				end
			end
		end
	end

	Spells:HealAoE(position, radius, caster, heal, true)

	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_life_pulse/omni_life_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	radius = radius * 0.87
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))	
end

function OmniPulses:OmniDeathPulse(caster, position, ignoreCaster, modifierElements, factor)
	local radius = OMNI_SPELLS_RADIUSES[1] * factor
	local damage = 100 * factor
	local deathPart = 0.33
	local color = Vector(255, 0, 0)
	local deathOnly = true

	local deathInd = table.indexOf(modifierElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		table.remove(modifierElements, deathInd)
		deathPart = 0.67
		damage = damage + 50 * factor
		radius = OMNI_SPELLS_RADIUSES[2] * factor
		if modifierElements[1] == ELEMENT_DEATH then
			modifierElements[1] = nil
			deathPart = 1.0
			radius = OMNI_SPELLS_RADIUSES[3] * factor
			damage = damage + 50 * factor
		elseif modifierElements[1] == ELEMENT_FIRE then
			damage = damage + 75 * factor
			color = Vector(255, 100, 0)
			deathOnly = false
			OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, damage * 0.33)
		elseif modifierElements[1] == ELEMENT_COLD then
			damage = damage + 30 * factor
			color = Vector(163, 222, 255)
			deathOnly = false
			OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, damage * 0.33)
		elseif modifierElements[1] == ELEMENT_WATER then
			deathPart = 1.0
			damage = damage + 20 * factor
			color = Vector(0, 72, 255)
			deathOnly = false
			OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false, false)
		else
			deathPart = 1.0
		end
	else
		local fireInd = table.indexOf(modifierElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(modifierElements, fireInd)

			damage = damage + 50 * factor
			deathOnly = false
			if modifierElements[1] == ELEMENT_FIRE then
				damage = damage + 60 * factor
				color = Vector(255, 100, 0)
				OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, damage * 0.67)
			elseif modifierElements[1] == ELEMENT_WATER then
				damage = damage + 125 * factor
				color = Vector(160, 160, 160)
				OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, damage * 0.67, false)
			else
				deathPart = 0.5
				color = Vector(255, 100, 0)
				OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, damage * 0.5)
			end
		else
			local waterInd = table.indexOf(modifierElements, ELEMENT_WATER)
			if waterInd ~= nil then
				table.remove(modifierElements, waterInd)

				deathPart = 1.0
				damage = damage + 10 * factor
				color = Vector(0, 72, 255)
				deathOnly = false
				if modifierElements[1] == ELEMENT_WATER then
					damage = damage + 10 * factor
					OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, true)
				else
					OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false)
				end
			else
				local coldInd = table.indexOf(modifierElements, ELEMENT_COLD)
				if coldInd ~= nil then
					table.remove(modifierElements, coldInd)
					damage = damage + 30 * factor
					color = Vector(163, 222, 255)
					deathOnly = false
					if modifierElements[1] == ELEMENT_COLD then
						damage = damage + 30 * factor
						OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, damage * 0.67)
					else
						deathPart = 0.5
						OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, damage * 0.5)
					end
				else
					deathPart = 1.0
				end
			end
		end
	end

	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_DEATH, damage * deathPart, true)
	
	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_death_pulse/omni_death_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, deathOnly and 1 or 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, color)
end