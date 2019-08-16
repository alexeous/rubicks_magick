if OmniIceSpikes == nil then
	OmniIceSpikes = class({})
end

function OmniIceSpikes:Precache(context)
	PrecacheResource("particle_folder", "particles/omni_ice_spikes", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/omni_ice_spikes.vsndevts", context)

	PrecacheResource("soundfile", "sounds/weapons/hero/ancient_apparition/cold_feet_tick2.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/leshrac/split_earth.vsnd", context)
	PrecacheResource("soundfile", "sounds/weapons/hero/crystal_maiden/crystal_nova.vsnd", context)
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

	HP:ApplyElementAoE(position, radius, caster, PSEUDO_ELEMENT_ICE, 225, true)

	local particle = ParticleManager:CreateParticle("particles/omni_ice_spikes/omni_ice_spikes.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)

	Util:EmitSoundOnLocation(position, "OmniIceSpikes1", caster)
	Util:EmitSoundOnLocation(position, "OmniIceSpikes2", caster)
	Util:EmitSoundOnLocation(position, "OmniIceSpikes3", caster)
end