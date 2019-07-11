if StoneWall == nil then
	StoneWall = class({})
end

function StoneWall:Precache(context)
	LinkLuaModifier("modifier_stone_wall", "modifiers/modifier_stone_wall.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource("particle_folder", "particles/stone_wall", context)
end

function StoneWall:PlayerConnected(player)
end


function StoneWall:PlaceStoneWallSpell(player, modifierElement)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.17,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.0,
		castingGestureTranslate = "wall",
		endFunction = function(player) StoneWall:PlaceStoneWall(player:GetAssignedHero(), modifierElement) end
	}
	Spells:StartCasting(player, spellCastTable)
end

function StoneWall:PlaceStoneWall(caster, modifierElement)
	local wall = StoneWall:CreateWall(caster:GetAbsOrigin() + caster:GetForwardVector() * 200, caster:GetForwardVector())
	Timers:CreateTimer(10, function() if not wall:IsNull() then wall:Destroy() end end)
end

function StoneWall:CreateWall(position, forwardVec)
	local wall = Util:CreateDummyWithoutModifier(position)
	wall:SetHullRadius(50)
	wall:AddNewModifier(wall, nil, "modifier_stone_wall", {})
	wall.isWall = true
	wall.isSolidWall = true
	wall.shieldElements = { ELEMENT_EARTH, ELEMENT_EARTH, ELEMENT_LIGHTNING, ELEMENT_LIGHTNING }

	local particle = ParticleManager:CreateParticle("particles/stone_wall/stone_wall.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControlForward(particle, 0, forwardVec)
	wall.particle = particle

	return wall
end