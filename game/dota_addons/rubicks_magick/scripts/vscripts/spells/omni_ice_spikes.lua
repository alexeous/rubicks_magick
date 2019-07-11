if OmniIceSpikes == nil then
	OmniIceSpikes = class({})
end

function OmniIceSpikes:Precache(context)
	PrecacheResource("particle_folder", "particles/omni_ice_spikes", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/omni_ice_spikes.vsndevts", context)
end

function OmniIceSpikes:PlayerConnected(player)

end


function OmniIceSpikes:OmniIceSpikesSpell(player, modifierElement)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.2,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_6,
		castingGestureRate = 1.98,
		thinkPeriod = 0.45,
		thinkFunction = function(player)
			player.spellCast.thinkFunction = nil
			OmniIceSpikes:OmniIceSpikes(player:GetAssignedHero(), modifierElement)
		end
	}
	Spells:StartCasting(player, spellCastTable)
end

function OmniIceSpikes:OmniIceSpikes(caster, modifierElement)
	local baseDamage = 225
	local radius = OMNI_SPELLS_RADIUSES[1]
	local position = caster:GetAbsOrigin()

	if modifierElement ~= nil then
		local additionalFuncTable = {
			[ELEMENT_WATER]	= function() OmniElementSprays:OmniWaterSpray(caster, position, radius, true, false) end,
			[ELEMENT_COLD]	= function() OmniElementSprays:OmniColdSpray(caster, position, radius, true, 45) end,
			[ELEMENT_DEATH]	= function() OmniPulses:OmniDeathPulse(caster, position, true, { ELEMENT_DEATH }) end,
			[ELEMENT_LIFE]	= function() OmniPulses:OmniLifePulse(caster, position, true, { ELEMENT_LIFE }) end
		}
		local additionalFunc = additionalFuncTable[modifierElement]
		if additionalFunc ~= nil then
			additionalFunc()
		end
	end

	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_WATER, baseDamage / 2, true, false)
	Spells:ApplyElementDamageAoE(position, radius, caster, ELEMENT_COLD, baseDamage / 2, true, false, nil, true)

	local particle = ParticleManager:CreateParticle("particles/omni_ice_spikes/omni_ice_spikes.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)

	Util:EmitSoundOnLocation(position, "OmniIceSpikes1", caster)
	Util:EmitSoundOnLocation(position, "OmniIceSpikes2", caster)
	Util:EmitSoundOnLocation(position, "OmniIceSpikes3", caster)
end