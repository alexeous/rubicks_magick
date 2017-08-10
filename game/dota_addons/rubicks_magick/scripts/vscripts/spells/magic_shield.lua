if MagicShield == nil then
	MagicShield = class({})
end

FLAT_SHIELD = 1
ROUND_SHIELD = 2

ROUND_SHIELD_RADIUS = 400
FLAT_SHIELD_WIDTH = 50
FLAT_SHIELD_LENGTH = 400

function MagicShield:Precache(context)
	PrecacheResource("model", "models/particle/sphere.vmdl", context)
	PrecacheResource("particle_folder", "particles/magic_shield/round_shield", context)
	PrecacheResource("particle_folder", "particles/magic_shield/flat_shield", context)
end

function MagicShield:Init()
	MagicShield.shields = {}
end

function MagicShield:PlayerConnected(player)
end


function MagicShield:PlaceFlatMagicShieldSpell(player)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.3,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureRate = 2.0,
		castingGestureTranslate = "wall",
		endFunction = function(player) MagicShield:PlaceFlatMagicShield(player) end
	}
	Spells:StartCasting(player, spellCastTable)

end

function MagicShield:PlaceRoundMagicShieldSpell(player)
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 0.3,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_5,
		castingGestureTranslate = "remnant",
		endFunction = function(player) MagicShield:PlaceRoundMagicShield(player) end
	}
	Spells:StartCasting(player, spellCastTable)
end

function MagicShield:PlaceFlatMagicShield(player)	
	local heroEntity = player:GetAssignedHero()
	local forward = heroEntity:GetForwardVector():Normalized()
	local right = heroEntity:GetRightVector():Normalized()
	local center = heroEntity:GetAbsOrigin() + forward * 40
	forward = forward * (FLAT_SHIELD_WIDTH / 2)
	right = right * (FLAT_SHIELD_LENGTH / 2)
	local corners = {
		center + forward + right,
		center + forward - right,
		center - forward - right,
		center - forward + right
	}
	local particle = ParticleManager:CreateParticle("particles/magic_shield/flat_shield/flat_shield.vpcf", PATTACH_CUSTOMORIGIN, nil)
	MagicShield:AddShield(player, { type = FLAT_SHIELD, center = center, corners = corners, particle = particle })
end

function MagicShield:PlaceRoundMagicShield(player)
	local center = player:GetAssignedHero():GetAbsOrigin()
	local particle = ParticleManager:CreateParticle("particles/magic_shield/round_shield/round_shield.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, center)
	MagicShield:AddShield(player, { type = ROUND_SHIELD, center = center, particle = particle })
end

function MagicShield:AddShield(player, shield)
	shield.destroy = function()
		ParticleManager:DestroyParticle(shield.particle, false)
		local index = table.indexOf(MagicShield.shields, shield)
		table.remove(MagicShield.shields, index)
		if player.currentShield == shield then
			player.currentShield = nil
		end
		shield = nil
	end
	if player.currentShield ~= nil then
		player.currentShield.destroy()
	end
	player.currentShield = shield
	Timers:CreateTimer(0.1, function()
		if shield.type == ROUND_SHIELD then
			MagicShield:ResolveRoundShieldIntersections(shield) 
		elseif shield.type == FLAT_SHIELD then
			MagicShield:ResolveFlatShieldIntersections(shield) 
		end
	end)
	Timers:CreateTimer(5.0, function() if (shield ~= nil) then  shield.destroy() end  end)
end

function MagicShield:ResolveRoundShieldIntersections(newShield)
	local destroy = false
	for _, shield in pairs(MagicShield.shields) do
		if shield ~= newShield then
			if shield.type == ROUND_SHIELD then
				local distance = (shield.center - newShield.center):Length2D()
				if distance < ROUND_SHIELD_RADIUS then
					destroy = true
					shield.destroy()
				end
			elseif shield.type == FLAT_SHIELD then
				for _, corner in pairs(shield.corners) do
					local distance = (corner - newShield.center):Length2D()
					if distance < ROUND_SHIELD_RADIUS + 20 then
						destroy = true
						shield.destroy()
						break
					end
				end
			end
		end
	end
	if destroy then
		newShield.destroy()
	end
end

function MagicShield:ResolveArcShieldIntersections(newShield)
	local destroy = false
	for _, shield in pairs(MagicShield.shields) do
		if shield ~= newShield then
			if shield.type == ROUND_SHIELD then
				for _, corner in pairs(newShield.corners) do
					local distance = (corner - shield.center):Length2D()
					if distance < ROUND_SHIELD_RADIUS + 20 then
						destroy = true
						shield.destroy()
						break
					end
				end
			elseif shield.type == FLAT_SHIELD then
				
			end
		end
	end
	if destroy then
		newShield.destroy()
	end
end

function MagicShield:GetShieldCollidesPoint(point)
	for _, shield in pairs(MagicShield.shields) do
		
	end
end