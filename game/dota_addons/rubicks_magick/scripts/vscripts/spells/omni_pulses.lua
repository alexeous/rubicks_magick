if OmniPulses == nil then
	OmniPulses = class({})
end

function OmniPulses:Precache(context)
	PrecacheResource("particle_folder", "particles/omni_pulses/omni_death_pulse", context)
	PrecacheResource("particle_folder", "particles/omni_pulses/omni_life_pulse", context)
	
	PrecacheResource("soundfile", "soundevents/rubicks_magick/omni_pulses.vsndevts", context)
end

function OmniPulses:PlayerConnected(player)
end


function OmniPulses:OmniLifePulseSpell(player, pickedElements)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.0,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.1,
		castingGestureTranslate = "shadowraze"
	}
	Spells:StartCasting(player, spellCastTable)

	local heroEntity = player:GetAssignedHero()
	OmniPulses:OmniLifePulse(heroEntity, heroEntity:GetAbsOrigin(), true, pickedElements)
end

function OmniPulses:OmniDeathPulseSpell(player, pickedElements)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.0,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.9,
		castingGestureTranslate = "shadowraze"
	}
	Spells:StartCasting(player, spellCastTable)

	local heroEntity = player:GetAssignedHero()
	OmniPulses:OmniDeathPulse(heroEntity, heroEntity:GetAbsOrigin(), true, pickedElements)
end

function OmniPulses:OmniLifePulse(caster, position, ignoreCaster, pickedElements, radiusFactor, healFactor)
	while pickedElements[1] ~= ELEMENT_LIFE and pickedElements[1] ~= nil do
		table.remove(pickedElements, 1)
	end
	radiusFactor = radiusFactor or 1.0
	healFactor = healFactor or 1.0
	local radius = OMNI_SPELLS_RADIUSES[1] * radiusFactor
	local heal = 100 * healFactor
	if pickedElements[2] == ELEMENT_LIFE then
		radius = OMNI_SPELLS_RADIUSES[2] * radiusFactor
		heal = 140 * healFactor
	end

	local lifePulseTable = {
		[ELEMENT_LIFE] = {
			[ELEMENT_LIFE] = {
				[ELEMENT_WATER] = function() OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false, false) end,
				[ELEMENT_FIRE]  = function() OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 73 * healFactor) end,
				[ELEMENT_COLD]  = function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 43 * healFactor) end
			},
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE]  = function() OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, 125 * healFactor, false) end,
				[DEFAULT]       = function() OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, (pickedElements[3] == ELEMENT_WATER)) end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE]  = function() OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 106 * healFactor) end,
				[EMPTY]         = function() OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 75 * healFactor) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD]  = function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 104 * healFactor) end,
				[EMPTY]         = function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 56 * healFactor) end
			}
		}
	}
	local func = table.serialRetrieve(lifePulseTable, pickedElements)
	if func ~= nil then
		func()
	end
	
	Spells:HealAoE(position, radius, caster, heal, ignoreCaster)

	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_life_pulse/omni_life_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	radius = radius * 0.87
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))
	
	Util:EmitSoundOnLocation(position, "OmniLifePulse1", caster)
	Util:EmitSoundOnLocation(position, "OmniLifePulse2", caster)
end

function OmniPulses:OmniDeathPulse(caster, position, ignoreCaster, pickedElements, radiusFactor, damageFactor)
	while pickedElements[1] ~= ELEMENT_DEATH and pickedElements[1] ~= nil do
		table.remove(pickedElements, 1)
	end
	radiusFactor = radiusFactor or 1.0
	damageFactor = damageFactor or 1.0
	local power = table.count(pickedElements, ELEMENT_DEATH)
	local radius = OMNI_SPELLS_RADIUSES[power] * radiusFactor
	local deathDamages = { 100, 140, 174 }
	local deathDamage = deathDamages[power] * damageFactor
	local color = Vector(255, 0, 0)

	local deathPulseTable = {
		[ELEMENT_DEATH] = {
			[ELEMENT_DEATH] = {
				[ELEMENT_WATER] = function()
					color = Vector(0, 72, 255)
					OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false)
				end,
				[ELEMENT_FIRE] = function()
					color = Vector(255, 100, 0)
					OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 76 * damageFactor)
				end,
				[ELEMENT_COLD] = function()
					color = Vector(163, 222, 255)
					OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 46 * damageFactor)
				end
			},
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function()
					color = Vector(160, 160, 160)
					OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, 125 * damageFactor, false)					
				end,
				[DEFAULT] = function()
					color = Vector(0, 72, 255)
					OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, (pickedElements[3] == ELEMENT_WATER))
				end
			},
			[ELEMENT_FIRE] = function()
				color = Vector(255, 100, 0)
				local damage = (pickedElements[3] == ELEMENT_FIRE) and 106 or 75
				OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, damage * damageFactor)
			end,
			[ELEMENT_COLD] = function() 
				color = Vector(163, 222, 255)
				local damage = (pickedElements[1] == ELEMENT_COLD) and 63 or 45
				OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, damage * damageFactor)
			end
		}
	}
	local func = table.serialRetrieve(deathPulseTable, pickedElements)
	if func ~= nil then
		func()
	end
	
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_DEATH, deathDamage, ignoreCaster)
	
	local deathOnly = (color == Vector(255, 0, 0)) and 1 or 0
	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_death_pulse/omni_death_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, deathOnly))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, color)
	
	Util:EmitSoundOnLocation(position, "OmniDeathPulse", caster)
end