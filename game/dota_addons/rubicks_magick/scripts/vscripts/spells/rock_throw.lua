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
		duration = 3.0,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		endFunction = function(player) RockThrow:ReleaseRock(player) end,
		slowMovePercentage = 30
	}
	Spells:StartCasting(player, spellCastTable)
end

function RockThrow:ReleaseRock(player)

end