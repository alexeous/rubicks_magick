if MagicShield == nil then
	MagicShield = class({})
end

FLAT_SHIELD = 1
ROUND_SHIELD = 2

ROUND_SHIELD_RADIUS = 400
FLAT_SHIELD_WIDTH = 100
FLAT_SHIELD_LENGTH = 400
ROUND_SHIELD_RADIUS_SQR = ROUND_SHIELD_RADIUS * ROUND_SHIELD_RADIUS

function MagicShield:Precache(context)
	PrecacheResource("model", "models/particle/sphere.vmdl", context)
	PrecacheResource("model", "models/props_debris/smallprops/smallprops_bronze_plate.vmdl", context)
	PrecacheResource("particle_folder", "particles/magic_shield/round_shield", context)
	PrecacheResource("particle_folder", "particles/magic_shield/flat_shield", context)
	
	PrecacheResource("soundfile", "soundevents/rubicks_magick/magic_shield.vsndevts", context)
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
	local hero = player:GetAssignedHero()
	local forwardN = hero:GetForwardVector():Normalized()
	local rightN = hero:GetRightVector():Normalized()
	local center = hero:GetAbsOrigin() + forwardN * 120
	local forward = forwardN * (FLAT_SHIELD_WIDTH / 2)
	local right = rightN * (FLAT_SHIELD_LENGTH / 2)
	local corners = {
		center + forward + right,
		center + forward - right,
		center - forward - right,
		center - forward + right,
		center + forward + right	-- repeat to loop
	}
	local axes = {
		corners[2] - corners[1],
		corners[4] - corners[1]
	}
	local origin = {}
	for i = 1, 2 do
		axes[i] = axes[i] / (axes[i].x * axes[i].x + axes[i].y * axes[i].y)
		origin[i] = corners[1]:Dot(axes[i])
	end

	local particle = ParticleManager:CreateParticle("particles/magic_shield/flat_shield/flat_shield.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, center + forwardN * 40 + Vector(0, 0, 50))
	ParticleManager:SetParticleControlOrientation(particle, 0, forwardN, rightN, Vector(0, 0, 1))
	ParticleManager:SetParticleControl(particle, 1, Vector(0, 0, hero:GetAngles().y + 90))
	MagicShield:AddShield(player, { type = FLAT_SHIELD, center = center, corners = corners, axes = axes, origin = origin, particle = particle })

	hero:EmitSound("MagicShieldPlace1")
	hero:EmitSound("MagicShieldPlace2")
end

function MagicShield:PlaceRoundMagicShield(player)
	local hero = player:GetAssignedHero()
	local center = hero:GetAbsOrigin()
	local particle = ParticleManager:CreateParticle("particles/magic_shield/round_shield/round_shield.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, center)
	MagicShield:AddShield(player, { type = ROUND_SHIELD, center = center, particle = particle })

	hero:EmitSound("MagicShieldPlace1")
	hero:EmitSound("MagicShieldPlace2")
end

function MagicShield:AddShield(player, shield)
	local soundDummy = Util:CreateDummy(shield.center, player:GetAssignedHero())
	soundDummy:EmitSound("MagicShieldLoop")
	shield.destroy = function()
		ParticleManager:DestroyParticle(shield.particle, false)
		soundDummy:StopSound("MagicShieldLoop")
		soundDummy:Destroy()
		table.removeItem(MagicShield.shields, shield)
		if player.currentShield == shield then
			player.currentShield = nil
		end
		shield = nil
	end
	if player.currentShield ~= nil then
		player.currentShield.destroy()
	end
	player.currentShield = shield
	table.insert(MagicShield.shields, shield)
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
	local destroyList = {}
	for _, shield in pairs(MagicShield.shields) do
		if shield ~= newShield then
			if shield.type == ROUND_SHIELD then
				local distance = (shield.center - newShield.center):Length2D()
				if distance < ROUND_SHIELD_RADIUS * 2 then
					table.insert(destroyList, shield)
				end
			elseif shield.type == FLAT_SHIELD then
				for _, corner in pairs(shield.corners) do
					local distance = (corner - newShield.center):Length2D()
					if distance < ROUND_SHIELD_RADIUS + 20 then
						table.insert(destroyList, shield)
						break
					end
				end
			end
		end
	end
	if next(destroyList) ~= nil then
		for _, shield in pairs(destroyList) do
			shield.destroy()
		end
		newShield.destroy()
	end
end

function MagicShield:ResolveFlatShieldIntersections(newShield)
	local destroyList = {}
	for _, shield in pairs(MagicShield.shields) do
		if shield ~= newShield then
			if shield.type == ROUND_SHIELD then
				for _, corner in pairs(newShield.corners) do
					local distance = (corner - shield.center):Length2D()
					if distance < ROUND_SHIELD_RADIUS + 20 then
						table.insert(destroyList, shield)
						break
					end
				end
			elseif shield.type == FLAT_SHIELD then
				if MagicShield:Overlaps1Way(shield, newShield) and MagicShield:Overlaps1Way(newShield, shield) then
					table.insert(destroyList, shield)
				end
			end
		end
	end
	if next(destroyList) ~= nil then
		for _, shield in pairs(destroyList) do
			shield.destroy()
		end
		newShield.destroy()
	end
end

function MagicShield:Overlaps1Way(shield1, shield2)
	for i = 1, 2 do
		local tMin = shield2.corners[1]:Dot(shield1.axes[i])
		local tMax = tMin
		for j = 2, 4 do
			local t = shield2.corners[j]:Dot(shield1.axes[i])
			if t < tMin then
				tMin = t
			elseif t > tMax then
				tMax = t
			end
		end
		if (tMin > 1 + shield1.origin[i]) or (tMax < shield1.origin[i]) then
			return false
		end
	end
	return true
end

function MagicShield:DoesPointOverlapRoundShields(point)
	for _, shield in pairs(MagicShield.shields) do
		if shield.type == ROUND_SHIELD and MagicShield:DoesPointOverlapShield(point, shield) then
			return true
		end
	end
	return false
end

function MagicShield:DoesPointOverlapFlatShields(point)
	for _, shield in pairs(MagicShield.shields) do
		if shield.type == FLAT_SHIELD and MagicShield:DoesPointOverlapShield(point, shield) then
			return true
		end
	end
	return false
end

function MagicShield:DoesPointOverlapShields(point)
	for _, shield in pairs(MagicShield.shields) do
		if MagicShield:DoesPointOverlapShield(point, shield) then
			return true
		end
	end
	return false
end

function MagicShield:DoesPointOverlapShield(point, shield)
	if shield.type == ROUND_SHIELD then
		local distance = (point - shield.center):Length2D()
		if distance < ROUND_SHIELD_RADIUS then
			return true
		end
	elseif shield.type == FLAT_SHIELD then
		local t1 = point:Dot(shield.axes[1])
		local t2 = point:Dot(shield.axes[2])
		if (t1 > shield.origin[1] and t1 < 1 + shield.origin[1]) and 
		   (t2 > shield.origin[2] and t2 < 1 + shield.origin[2]) then
			return true
		end
	end
	return false
end

function MagicShield:TraceLine(pStart, pEnd)
	local result = nil
	local minDistance
	local vecNormalized = (pEnd - pStart):Normalized()
	local pxMin, pxMax = pStart.x, pEnd.x
	if pEnd.x < pStart.x then
		pxMin, pxMax = pEnd.x, pStart.x
	end

	local k = vecNormalized.y / vecNormalized.x
	local b = -k*pStart.x + pStart.y

	for _, shield in pairs(MagicShield.shields) do
		if shield.type == ROUND_SHIELD then
			local h = CalcDistanceToLineSegment2D(shield.center, pStart, pEnd)
			if h <= ROUND_SHIELD_RADIUS then
				local cx = (shield.center.x / k + shield.center.y - b) / (k + 1/k)
				local cy = -cx / k + shield.center.x / k + shield.center.y
				local c = Vector(cx, cy, pStart.z)
				local d = math.sqrt(ROUND_SHIELD_RADIUS_SQR - h*h)
				local intersectPoints = { c + d*vecNormalized, c - d*vecNormalized }
				for i = 1, 2 do
					if intersectPoints[i].x >= pxMin and intersectPoints[i].x <= pxMax then
						local distance = (pStart - intersectPoints[i]):Length2D()
						if result == nil or distance < minDistance then
							result = { point = intersectPoints[i], normal = (intersectPoints[i] - shield.center):Normalized(), distance = distance }
							minDistance = distance
						end
					end
				end
			end
		elseif shield.type == FLAT_SHIELD then
			for i = 1, 4 do
				local sPoint1 = shield.corners[i]
				local sPoint2 = shield.corners[i+1]
				local xMin, xMax = sPoint1.x, sPoint2.x
				if sPoint2.x < sPoint1.x then
					xMin, xMax = sPoint2.x, sPoint1.x
				end
				local kSide = (sPoint2.y - sPoint1.y) / (sPoint2.x - sPoint1.x)
				local bSide = -kSide*sPoint1.x + sPoint1.y
				local intersectX = (bSide - b) / (k - kSide)
				if intersectX >= pxMin and intersectX <= pxMax and intersectX >= xMin and intersectX <= xMax then
					local intersectPoint = Vector(intersectX, k*intersectX + b, pStart.z)
					local distance = (pStart - intersectPoint):Length2D()
					if result == nil or distance < minDistance then
						local vec = (sPoint2 - sPoint1):Normalized()
						result = { point = intersectPoint, normal = Vector(-vec.y, vec.x, 0), distance = distance }
						minDistance = distance
					end
				end
			end
		end
	end
	if result ~= nil then
		vecNormalized = -vecNormalized
		local dot = vecNormalized:Dot(result.normal)
		if dot < 0 then
			result.normal = -result.normal
			dot = -dot
		end
		result.reflectedDirection = (2*dot*result.normal - vecNormalized):Normalized()
	end
	return result
end