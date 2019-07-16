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
		duration = 0.75,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.0,
		castingGestureTranslate = "wall",
		thinkPeriod = 0.17,
		thinkFunction = function(player) 
			player.spellCast.thinkFunction = nil
			Spells:RemoveMagicShieldAndSolidWalls(player)
			StoneWall:PlaceStoneWall(player:GetAssignedHero(), modifierElement)
		end
	}
	Spells:StartCasting(player, spellCastTable)
	GenericWall:KnockbackAllAwayFromWall(player:GetAssignedHero())
end

function StoneWall:PlaceStoneWall(caster, modifierElement)
	local onKilledCallback = function(wall, isQuietKill)
		StoneWall:OnWallKilled(wall, caster, isQuietKill)
	end
	local wallUnits = GenericWall:CreateWallUnits(caster, 4, 40, { ELEMENT_EARTH, ELEMENT_LIGHTNING }, onKilledCallback)
	for _, wall in pairs(wallUnits) do
		StoneWall:InitWallUnit(wall)
		
		caster.solidWalls = caster.solidWalls or {}
		table.insert(caster.solidWalls, wall)
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

function StoneWall:OnWallKilled(wall, caster, isQuietKill)
	if wall.killTimer ~= nil then
		Timers:RemoveTimer(wall.killTimer)
	end
	ParticleManager:DestroyParticle(wall.particle, false)
	
	if caster.solidWalls ~= nil then
		table.removeItem(caster.solidWalls, wall)
	end
end