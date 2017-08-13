if Beams == nil then
	Beams = class({})
end

function Beams:Precache(context)

end

function Beams:PlayerConnected(player)

end


function Beams:StartLifeBeam(player, modifierElements)
	-------- TODO ---------
end

function Beams:StartDeathBeam(player, modifierElements)
	-------- TODO ---------
	local spellCastTable = {
		castType = CAST_TYPE_CONTINUOUS,
		duration = 5.0,
		slowMovePercentage = 30,
		turnDegsPerSec = 60.0,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		castingGestureTranslate = "black_hole",
		castingGestureRate = 1.5,
		thinkFunction = function(player) Beams:B(player) end
	}
	Spells:StartCasting(player, spellCastTable)
end

function Beams:B(player)
	local h = player:GetAssignedHero()
	local forw = h:GetForwardVector()
	local orig = h:GetAbsOrigin()
	local hit = MagicShield:CastLine(orig, orig + forw * 2500)
	if hit ~= nil then
		DebugDrawLine(orig, hit.point, 50, 255, 255, false, SPELLS_THINK_PERIOD)
		DebugDrawLine(hit.point, hit.point + hit.normal * 300, 50, 255, 255, false, SPELLS_THINK_PERIOD)
		DebugDrawLine(hit.point, hit.point + hit.reflectedDirection * 2500, 50, 255, 255, false, SPELLS_THINK_PERIOD)
	else
		DebugDrawLine(orig, orig + forw * 2500, 50, 255, 255, false, SPELLS_THINK_PERIOD)
	end
end