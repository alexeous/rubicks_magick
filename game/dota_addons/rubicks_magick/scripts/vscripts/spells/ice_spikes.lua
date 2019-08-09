if IceSpikes == nil then
	IceSpikes = class({})
end

function IceSpikes:Precache(context)

end

function IceSpikes:PlayerConnected(player)

end


function IceSpikes:StartIceSpikes(player, modifierElement)
	local caster = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_CHARGING,
		duration = 2.6,
		cooldown = 0.4,
		chargingPhase1Duration = 2.1,
		chargingPhase2Duration = 0.5,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) 
			IceSpikes:ReleaseSpikes(player, modifierElement)
		end,
		thinkPeriod = 2.1,
		thinkFunction = function(player)
			caster:EmitSound("RockOvercharge")
		end,
		slowMovePercentage = 50,
		chargingParticle = "particles/rock_throw/charging_particle/charging_particle.vpcf"
	}
	Spells:StartCasting(player, spellCastTable)
	caster:EmitSound("RockCharging")
end

function IceSpikes:ReleaseSpikes(player, modifierElement)
	caster:StopSound("RockCharging")
	caster:StopSound("RockOvercharge")

	local timeElapsed = Spells:TimeElapsedSinceCast(player)
end