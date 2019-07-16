require("spells/generic_wall")

if StoneWall == nil then
	StoneWall = class({})
end

function StoneWall:Precache(context)
	PrecacheResource("particle_folder", "particles/stone_wall", context)
end

function StoneWall:PlayerConnected(player)
end


function StoneWall:PlaceStoneWallSpell(player, modifierElement)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.0,
		castingGestureTranslate = "wall",
		thinkPeriod = 0.17,
		thinkFunction = function(player) 
			player.spellCast.thinkFunction = nil
			StoneWall:PlaceStoneWall(player:GetAssignedHero(), modifierElement) 
		end
	}
	Spells:StartCasting(player, spellCastTable)
	GenericWall:KnockbackAllAwayFromWall(player:GetAssignedHero())
end

function StoneWall:PlaceStoneWall(caster, modifierElement)
	local wallUnits = GenericWall:CreateWallUnits(caster, 4, 40, { ELEMENT_EARTH, ELEMENT_LIGHTNING }, StoneWall.OnWallDestroyed)
	for _, wall in pairs(wallUnits) do
		StoneWall:InitWallUnit(wall)
	end
end

function StoneWall:InitWallUnit(wall)
	wall:SetHullRadius(50)
	wall.isSolidWall = true

	local particle = ParticleManager:CreateParticle("particles/stone_wall/stone_wall.vpcf", PATTACH_ABSORIGIN, wall)
	wall.particle = particle
	
	wall.killTimer = Timers:CreateTimer(10, function() 
		wall.killTimer = nil
		if not wall:IsNull() then 
			wall:Kill(nil, nil)
		end 
	end)
end

function StoneWall.OnWallDestroyed(wall)
	if wall.killTimer ~= nil then
		Timers:RemoveTimer(wall.killTimer)
	end
	ParticleManager:DestroyParticle(wall.particle, false)
end