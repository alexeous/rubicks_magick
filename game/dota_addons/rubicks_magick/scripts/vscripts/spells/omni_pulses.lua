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
		duration = 1.0,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.2,
		castingGestureTranslate = "purification"
	}
	Spells:StartCasting(player, spellCastTable)

	local heroEntity = player:GetAssignedHero()
	OmniPulses:OmniLifePulse(heroEntity, heroEntity:GetAbsOrigin(), true, modifierElements)
end

function OmniPulses:OmniDeathPulseSpell(player, modifierElements)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.0,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.7,
		castingGestureTranslate = "shadowraze"
	}
	Spells:StartCasting(player, spellCastTable)

	local heroEntity = player:GetAssignedHero()
	OmniPulses:OmniDeathPulse(heroEntity, heroEntity:GetAbsOrigin(), true, modifierElements)
end

function OmniPulses:OmniLifePulse(caster, position, ignoreCaster, modifierElements, radiusFactor, healFactor)
	radiusFactor = radiusFactor or 1.0
	healFactor = healFactor or 1.0
	local radius = OMNI_SPELLS_RADIUSES[1] * radiusFactor
	local heal = 100 * healFactor

	local lifeInd = table.indexOf(modifierElements, ELEMENT_LIFE)
	if lifeInd ~= nil then
		table.remove(modifierElements, lifeInd)

		radius = OMNI_SPELLS_RADIUSES[2] * radiusFactor
		heal = 140 * healFactor
		if modifierElements[1] == ELEMENT_FIRE then
			OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 73 * healFactor)
		elseif modifierElements[1] == ELEMENT_COLD then
			OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 43 * healFactor)
		elseif modifierElements[1] == ELEMENT_WATER then
			OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false, false)
		end
	else
		local fireInd = table.indexOf(modifierElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(modifierElements, fireInd)
			
			if modifierElements[1] == ELEMENT_WATER then
				OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, 125 * healFactor, false)
			else
				local damage = ((modifierElements[1] == ELEMENT_FIRE) and 106 or 75) * healFactor
				OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, damage)
			end
		else
			local waterInd = table.indexOf(modifierElements, ELEMENT_WATER)
			if waterInd ~= nil then
				table.remove(modifierElements, waterInd)

				local doPush = (modifierElements[1] == ELEMENT_WATER)
				OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, doPush)
			else
				local coldInd = table.indexOf(modifierElements, ELEMENT_COLD)
				if coldInd ~= nil then
					table.remove(modifierElements, coldInd)

					local damage = ((modifierElements[1] == ELEMENT_COLD) and 104 or 56) * healFactor
					OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, damage)
				end
			end
		end
	end

	Spells:HealAoE(position, radius, caster, heal, ignoreCaster)

	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_life_pulse/omni_life_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	radius = radius * 0.87
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))	
end

function OmniPulses:OmniDeathPulse(caster, position, ignoreCaster, modifierElements, radiusFactor, damageFactor)
	radiusFactor = radiusFactor or 1.0
	damageFactor = damageFactor or 1.0
	local radius = OMNI_SPELLS_RADIUSES[1] * radiusFactor
	local deathDamage = 100 * damageFactor
	local color = Vector(255, 0, 0)

	local deathInd = table.indexOf(modifierElements, ELEMENT_DEATH)
	if deathInd ~= nil then
		table.remove(modifierElements, deathInd)
		deathDamage  = 140 * damageFactor
		radius = OMNI_SPELLS_RADIUSES[2] * radiusFactor
		if modifierElements[1] == ELEMENT_DEATH then
			radius = OMNI_SPELLS_RADIUSES[3] * radiusFactor
			deathDamage = 174 * damageFactor
		elseif modifierElements[1] == ELEMENT_FIRE then
			color = Vector(255, 100, 0)
			OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 76 * damageFactor)
		elseif modifierElements[1] == ELEMENT_COLD then
			color = Vector(163, 222, 255)
			OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 46 * damageFactor)
		elseif modifierElements[1] == ELEMENT_WATER then
			color = Vector(0, 72, 255)
			OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false)
		end
	else
		local fireInd = table.indexOf(modifierElements, ELEMENT_FIRE)
		if fireInd ~= nil then
			table.remove(modifierElements, fireInd)

			if modifierElements[1] == ELEMENT_WATER then
				color = Vector(160, 160, 160)
				OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, 125 * damageFactor, false)
			else
				color = Vector(255, 100, 0)
				local damage = ((modifierElements[1] == ELEMENT_FIRE) and 106 or 75) * damageFactor
				OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, damage)
			end
		else
			local waterInd = table.indexOf(modifierElements, ELEMENT_WATER)
			if waterInd ~= nil then
				table.remove(modifierElements, waterInd)

				color = Vector(0, 72, 255)
				local doPush = (modifierElements[1] == ELEMENT_WATER)
				OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, doPush)
			else
				local coldInd = table.indexOf(modifierElements, ELEMENT_COLD)
				if coldInd ~= nil then
					table.remove(modifierElements, coldInd)

					color = Vector(163, 222, 255)
					local damage = ((modifierElements[1] == ELEMENT_COLD) and 63 or 45) * damageFactor
					OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, damage)
				end
			end
		end
	end

	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_DEATH, deathDamage, ignoreCaster)
	
	local deathOnly = (color == Vector(255, 0, 0)) and 1 or 0
	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_death_pulse/omni_death_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, deathOnly))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, color)
end