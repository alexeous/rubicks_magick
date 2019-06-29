if EarthStomp == nil then
	EarthStomp = class({})
end

function EarthStomp:Precache(context)
	LinkLuaModifier("modifier_stomp_stun", "modifiers/modifier_stomp_stun.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/earth_stomp", context)

	PrecacheResource("soundfile", "soundevents/rubicks_magick/earth_stomp.vsndevts", context)
end

function EarthStomp:PlayerConnected(player)

end


function EarthStomp:EarthStomp(player, pickedElements)
	local caster = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.4,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 0.82,
		castingGestureTranslate = "monkey_king_boundless_strike",
		thinkPeriod = 0.45,
		thinkFunction = function(player)
			EarthStomp:DoStomp(player, pickedElements)
		end
	}
	Spells:StartCasting(player, spellCastTable)
end

function EarthStomp:DoStomp(player, pickedElements)
	player.spellCast.thinkFunction = nil
	
	local caster = player:GetAssignedHero()
	local position = caster:GetAbsOrigin()
	
	local radiuses = OMNI_SPELLS_RADIUSES
	local radius = radiuses[table.count(pickedElements, ELEMENT_EARTH)]

	local stompTable = {
		[ELEMENT_EARTH] = {
			[ELEMENT_EARTH] = {
				[ELEMENT_LIFE]  = function() OmniPulses:OmniLifePulse(caster, position, true, pickedElements, nil, nil, radiuses[2]) end,
				[ELEMENT_DEATH] = function() OmniPulses:OmniDeathPulse(caster, position, true, pickedElements, nil, nil, radiuses[2]) end,
				[ELEMENT_FIRE]  = function() OmniElementSprays:OmniFireSpray(caster, position, radiuses[2], true, 75) end,
				[ELEMENT_COLD]  = function() OmniElementSprays:OmniColdSpray(caster, position, radiuses[2], true, 45) end,
				[ELEMENT_WATER] = function() OmniElementSprays:OmniWaterSpray(caster, position, radiuses[2], true, false) end
			},
			[ELEMENT_LIFE]  = function() OmniPulses:OmniLifePulse(caster, position, true, pickedElements, nil, nil, radiuses[1]) end,
			[ELEMENT_DEATH] = function() OmniPulses:OmniDeathPulse(caster, position, true, pickedElements, nil, nil, radiuses[1]) end,
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE]  = function() OmniElementSprays:OmniSteamSpray(caster, position, radiuses[1], true, 125, false) end,
				[ELEMENT_WATER] = function() OmniElementSprays:OmniWaterSpray(caster, position, radiuses[1], true, true) end,
				[EMPTY]         = function() OmniElementSprays:OmniWaterSpray(caster, position, radiuses[1], true, false) end,
				[ELEMENT_COLD]  = function() end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE]  = function() OmniElementSprays:OmniFireSpray(caster, position, radiuses[1], true, 106) end,
				[EMPTY]         = function() OmniElementSprays:OmniFireSpray(caster, position, radiuses[1], true, 75) end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD]  = function() OmniElementSprays:OmniColdSpray(caster, position, radiuses[1], true, 64) end,
				[EMPTY]         = function() OmniElementSprays:OmniColdSpray(caster, position, radiuses[1], true, 45) end
			}
		}
	}
	local func = table.serialRetrieve(stompTable, pickedElements)
	if func ~= nil then
		func()
	end

	EarthStomp:StunAoE(caster, radius)

	local onlyEarth = true
	for _, element in pairs(pickedElements) do
		if element ~= ELEMENT_EARTH and element ~= nil then
			onlyEarth = false
			break
		end
	end

	local particle = ParticleManager:CreateParticle("particles/earth_stomp/earth_stomp.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 1))
	ParticleManager:SetParticleControl(particle, 2, Vector(onlyEarth and 1 or 0, 0, 0))
	
	Util:EmitSoundOnLocation(position, "EarthStomp1", caster)
	Util:EmitSoundOnLocation(position, "EarthStomp2", caster)
end

function EarthStomp:StunAoE(caster, radius)
	local units = Util:FindUnitsInRadius(caster:GetAbsOrigin(), radius)
	for _, unit in pairs(units) do
		if unit ~= caster and 0 == Spells:ResistanceLevelTo(unit, ELEMENT_EARTH) then 
			unit:AddNewModifier(unit, nil, "modifier_stomp_stun", { duration = 1.2 })
		end
	end
end