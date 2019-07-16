if ElementWalls == nil then
	ElementWalls = class({})
end

function ElementWalls:Precache(context)

end

function ElementWalls:PlayerConnected(player)

end


function ElementWalls:PlaceIceWallSpell(player)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.18,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 1.2,
		castingGestureTranslate = "wall",
		thinkPeriod = 0.17,
		thinkFunction = function(player) 
			player.spellCast.thinkFunction = nil
			ElementWalls:PlaceIceWall(player:GetAssignedHero()) 
		end
	}
	Spells:StartCasting(player, spellCastTable)
	GenericWall:KnockbackAllAwayFromWall(player:GetAssignedHero())
end

function ElementWalls:PlaceSteamWall(player)
	-------- TODO ---------
end

function ElementWalls:PlaceWaterWall(player, modifierElement)
	-------- TODO ---------
end

function ElementWalls:PlaceFireWall(player, modifierElement)
	-------- TODO ---------
end

function ElementWalls:PlaceColdWall(player, modifierElement)
	-------- TODO ---------
end

function ElementWalls:PlaceIceWall(caster)

end