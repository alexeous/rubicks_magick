if OmniPulses == nil then
	OmniPulses = class({})
end

function OmniPulses:Precache(context)
	PrecacheResource("particle_folder", "particles/omni_pulses/omni_death_pulse", context)
	PrecacheResource("particle_folder", "particles/omni_pulses/omni_life_pulse", context)
	
	PrecacheResource("soundfile", "soundevents/rubicks_magick/omni_pulses.vsndevts", context)
	
	PrecacheResource("soundfile", "sounds/weapons/hero/warlock/shadowword_cast_heal.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/keeper/chakra_target.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/nevermore/shadowraze.vsnd", context)
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

	local hero = player:GetAssignedHero()
	OmniPulses:OmniLifePulse(hero, hero:GetAbsOrigin(), true, pickedElements)
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

	local hero = player:GetAssignedHero()
	OmniPulses:OmniDeathPulse(hero, hero:GetAbsOrigin(), true, pickedElements)
end

function OmniPulses:OmniLifePulse(caster, position, ignoreCaster, pickedElements, radiusFactor, healFactor, radiusOverride, healOverride)
	while pickedElements[1] ~= ELEMENT_LIFE and pickedElements[1] ~= nil do
		table.remove(pickedElements, 1)
	end

	radiusFactor = radiusFactor or 1.0
	healFactor = healFactor or 1.0
	local lifeCount = table.count(pickedElements, ELEMENT_LIFE)
	local radius = radiusOverride or (OMNI_SPELLS_RADIUSES[lifeCount] * radiusFactor)
	
	local healValues = { 100, 140 }
	local heal = healOverride or (healValues[lifeCount] * healFactor)

	local lifePulseTable = {
		[ELEMENT_LIFE] = {
			[ELEMENT_LIFE] = {
				[ELEMENT_WATER] = function() OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false, false) end,
				[ELEMENT_FIRE]  = function() OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 75 * healFactor) end,
				[ELEMENT_COLD]  = function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 45 * healFactor) end
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
				[ELEMENT_COLD]  = function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 63 * healFactor) end,
				[EMPTY]         = function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 45 * healFactor) end
			}
		}
	}
	local func = table.serialRetrieve(lifePulseTable, pickedElements)
	if func ~= nil then
		func()
	end
	
	HP:ApplyElementAoE(position, radius, caster, ELEMENT_LIFE, heal, ignoreCaster)

	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_life_pulse/omni_life_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	radius = radius * 0.87
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))
	
	Util:EmitSoundOnLocation(position, "OmniLifePulse1", caster)
	Util:EmitSoundOnLocation(position, "OmniLifePulse2", caster)
end

function OmniPulses:OmniDeathPulse(caster, position, ignoreCaster, pickedElements, radiusFactor, damageFactor, radiusOverride, damageOverride)
	while pickedElements[1] ~= ELEMENT_DEATH and pickedElements[1] ~= nil do
		table.remove(pickedElements, 1)
	end
	radiusFactor = radiusFactor or 1.0
	damageFactor = damageFactor or 1.0
	local power = table.count(pickedElements, ELEMENT_DEATH)
	local radius = radiusOverride or (OMNI_SPELLS_RADIUSES[power] * radiusFactor)
	local deathDamages = { 100, 140, 174 }
	local deathDamage = damageOverride or (deathDamages[power] * damageFactor)
	local color = OmniPulses:GetDeathOmniPulseColor(pickedElements)

	local deathPulseTable = {
		[ELEMENT_DEATH] = {
			[ELEMENT_DEATH] = {
				[ELEMENT_WATER] = function() OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, false) end,
				[ELEMENT_FIRE] 	= function() OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 76 * damageFactor)
				end,
				[ELEMENT_COLD] 	= function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 46 * damageFactor)
				end
			},
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] 	= function() OmniElementSprays:OmniSteamSpray(caster, position, radius, ignoreCaster, 125 * damageFactor, false)					
				end,
				[DEFAULT] 		= function() OmniElementSprays:OmniWaterSpray(caster, position, radius, ignoreCaster, (pickedElements[3] == ELEMENT_WATER))
				end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE]	= function() OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 106 * damageFactor) end,
				[EMPTY]			= function() OmniElementSprays:OmniFireSpray(caster, position, radius, ignoreCaster, 75 * damageFactor) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD]	= function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 63 * damageFactor) end,
				[EMPTY]			= function() OmniElementSprays:OmniColdSpray(caster, position, radius, ignoreCaster, 45 * damageFactor) end
			}
		}
	}
	local func = table.serialRetrieve(deathPulseTable, pickedElements)
	if func ~= nil then
		func()
	end
	
	HP:ApplyElementAoE(position, radius, caster, ELEMENT_DEATH, deathDamage, ignoreCaster)
	
	local deathOnly = (color == Vector(255, 0, 0)) and 1 or 0
	local particle = ParticleManager:CreateParticle("particles/omni_pulses/omni_death_pulse/omni_death_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, deathOnly))
	ParticleManager:SetParticleControl(particle, 2, Vector(radius / 250 + 0.2, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, color)
	
	Util:EmitSoundOnLocation(position, "OmniDeathPulse", caster)
end

function OmniPulses:GetDeathOmniPulseColor(pickedElements)
	local function contains(e) return table.indexOf(pickedElements, e) ~= nil end

	local color = Vector(255, 0, 0)
	if contains(ELEMENT_COLD) then 		color = Vector(163, 222, 255)
	elseif contains(ELEMENT_WATER) then
		if contains(ELEMENT_FIRE) then 	color = Vector(160, 160, 160)
		else 							color = Vector(0, 72, 255)
		end
	elseif contains(ELEMENT_FIRE) then	color = Vector(255, 100, 0)
	end
	return color
end