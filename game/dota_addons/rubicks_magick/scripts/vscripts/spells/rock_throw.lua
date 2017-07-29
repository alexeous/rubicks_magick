if RockThrow == nil then
	RockThrow = class({})
end

function RockThrow:Precache(context)

end

function RockThrow:PlayerConnected(player)

end


function RockThrow:StartRockThrow(player, modifierElements)
	local spellCastTable = {
		castType = CAST_TYPE_CHARGING,
		duration = 2.5,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) RockThrow:ReleaseRock(player) end,
		slowMovePercentage = 30,
		chargingParticle = "particles/rock_throw/charging_particle/charging_particle.vpcf"
	}
	Spells:StartCasting(player, spellCastTable)
end

function RockThrow:ReleaseRock(player)

end