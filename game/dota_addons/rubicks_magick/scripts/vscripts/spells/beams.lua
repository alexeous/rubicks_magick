if Beams == nil then
	Beams = class({})
end

BEAM_MAX_LENGTH = 2500
BEAM_COLLISION_WIDTH = 80
BEAM_TREE_DETECTION_STEPS = 5
BEAM_TREE_DETECTION_RADIUS = (BEAM_MAX_LENGTH / BEAM_TREE_DETECTION_STEPS) / 2

BEAM_MIN_BEAMS_ANGLE_DEG = 5
BEAM_COS_MIN_BEAMS_ANGLE = math.cos(math.rad(BEAM_MIN_BEAMS_ANGLE_DEG))

function Beams:Precache(context)	
	LinkLuaModifier("modifier_beam_target", "modifiers/modifier_beam_target.lua", LUA_MODIFIER_MOTION_NONE)
end

function Beams:Init()
	Beams.beams = {}
end

function Beams:PlayerConnected(player)
end


function Beams:StartLifeBeam(player, pickedElements)
	-------- TODO ---------
end

function Beams:StartDeathBeam(player, pickedElements)
	local particle = ParticleManager:CreateParticle("", PATTACH_CUSTOMORIGIN, nil)
	
	local effectFunction = function(target)

	end
	Beams:CreateBeam(player, particle, ELEMENT_DEATH, effectFunction)
end

function Beams:CreateBeam(player, particle, mainElement, effectFunction)
	local spellCastTable = {
		castType = CAST_TYPE_CONTINUOUS,
		duration = 7.0,
		slowMovePercentage = 30,
		turnDegsPerSec = 60.0,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		castingGestureTranslate = "black_hole",
		castingGestureRate = 1.5,
		thinkFunction = function(player) Beams:OnBeamsThink(player) end,
		endFunction = function(player) Beams:OnBeamStop(player) end,
		beams_Power = 0,
		beams_EffectFunction = effectFunction
	}
	Spells:StartCasting(player, spellCastTable)
	
	local heroEntity = player:GetAssignedHero()
	local origin = heroEntity:GetAbsOrigin()
	local direction = heroEntity:GetForwardVector():Normalized()
	local startPos = origin + direction * 100
	player.beam = Beams:CreateBeamSegment(player, startPos, direction, nil, mainElement, particle)
end

function Beams:CreateBeamSegment(player, startPos, direction, parentSegment, mainElement, particle)
	local beamSegment = {
		player = player,
		parent = parentSegment,
		mainElement = mainElement,
		particle = particle,
		startPos = startPos,
		direction = direction,
		endPos = startPos,
		creationTime = GameRules:GetGameTime()
	}
	Beams:UpdateParticle(beamSegment)
	beamSegment.destroy = function(isInterrupt)
		if beamSegment.child ~= nil then
			beamSegment.child.destroy(isInterrupt)
		end
		if beamSegment.entityTarget ~= nil then
			beamSegment.entityTarget:RemoveModifierByName("modifier_beam_target")
		end
		ParticleManager:DestroyParticle(beamSegment.particle, false)
		-- if isInterrupt then //start interrupt effect

		local index = table.indexOf(Beams.beamSegments, beamSegment)
		table.remove(Beams.beamSegments, index)
	end
	Timers:CreateTimer(0.1, function() Beams:RecalcBeamSegment(beamSegment) end)
	
	table.insert(Beams.beamSegments, beamSegment)
	return beamSegment
end

function Beams:RecalcBeamSegment(beamSegment)
	if MagicShield:DoesPointOverlapShields(beamSegment.startPos) then
		Beams:Interrupt(player)
		return
	end

	beamSegment.endPos = beamSegment.startPos + beamSegment.direction * BEAM_MAX_LENGTH
	local hitList = {}
	table.insert(hitList, Beams:EntitiesTrace(beamSegment))
	table.insert(hitList, Beams:TreesTrace(beamSegment))
	table.insert(hitList, Beams:BeamsTrace(beamSegment))
	table.insert(hitList, MagicShield:TraceLine(beamSegment.startPos, beamSegment.endPos))

	local noChild = true
	local noEntityTarget = true
	local minDistance = BEAM_MAX_LENGTH
	local closestHit = nil
	for _, hit in pairs(hitList) do
		if closestHit == nil or hit.distance < minDistance then
			minDistance = hit.distance
			closestHit = hit
		end
	end
	if closestHit ~= nil then
		beamSegment.endPos = hit.point
		if closestHit.reflectedDirection ~= nil then		-- hit magic shield
			noChild = false
			if beamSegment.direction:Dot(-closestHit.reflectedDirection) >= BEAM_COS_MIN_BEAMS_ANGLE then
				Beams:Interrupt(beamSegment.player)
				return
			else
				local childStart = beamSegment.endPos + closestHit.reflectedDirection * 0.01
				if beamSegment.child == nil then
					beamSegment.child = Beams:CreateBeamSegment(beamSegment.player, childStart, closestHit.reflectedDirection, beamSegment, beamSegment.mainElement)
				else
					beamSegment.child.startPos = childStart
					beamSegment.child.direction = closestHit.reflectedDirection
					Beams:RecalcBeamSegment(beamSegment.child)
				end
			end
		elseif closestHit.segment ~= nil then		-- hit another beam
			local cosDirsAngle = beamSegment.direction:Dot(-closestHit.segment.direction)
			if closestHit.segment.player == beamSegment.player then
				Beams:Interrupt(beamSegment.player)
				return
			elseif closestHit.segment.mainElement ~= beamSegment.mainElement or cosDirsAngle >= BEAM_COS_MIN_BEAMS_ANGLE then
				Beams:Interrupt(beamSegment.player)
				Beams:Interrupt(closestHit.segment.player)
				return
			else
				noChild = false
				local olderSegment = beamSegment
				if closestHit.segment.creationTime < beamSegment.creationTime then
					olderSegment = closestHit.segment
				end
				local childDirection = (beamSegment.direction + closestHit.segment.direction):Normalized()
				beamSegment.endPos = hit.point - beamSegment.direction * 0.01
				closestHit.segment.endPos = hit.point - closestHit.segment.direction * 0.01
				local childStart = olderSegment.endPos + childDirection * 0.01
				if olderSegment.child == nil then
					olderSegment.child = Beams:CreateBeamSegment(olderSegment.player, childStart, childDirection, olderSegment, olderSegment.mainElement)
				else
					olderSegment.child.startPos = childStart
					olderSegment.child.direction = childDirection
					Beams:RecalcBeamSegment(olderSegment.child)
				end
			end
		elseif closestHit.entity ~= nil and closestHit.entity.IsStunned ~= nil then 	-- hit an entity. IsStunned ~= nil is check for NPC
			noEntityTarget = false
			if beamSegment.entityTarget ~= nil and beamSegment.entityTarget ~= closestHit.entity then
				beamSegment.entityTarget:RemoveModifierByName("modifier_beam_target")
			end
			beamSegment.entityTarget = closestHit.entity
			if beamSegment.entityTarget:FindModifierByName("modifier_beam_target") == nil then
				local kv = { effectFunction = beamSegment.player.spellCast.beams_EffectFunction }
				beamSegment.entityTarget:AddNewModifier(beamSegment.player:GetAssignedHero(), nil, "modifier_beam_target", kv)
			end
		end
	end

	Beams:UpdateParticle(beamSegment)
	if beamSegment.child ~= nil and noChild then
		beamSegment.child.destroy(false)
		beamSegment.child = nil
	end
	if noEntityTarget then
		beamSegment.player.spellCast.beams_Power = 1 + beamSegment.player.spellCast.beams_Power
		if beamSegment.entityTarget ~= nil then
			beamSegment.entityTarget:RemoveModifierByName("modifier_beam_target")
		end
	else
		beamSegment.player.spellCast.beams_Power = beamSegment.player.spellCast.beams_Power - 1
	end

--[[
	if traceTable.hit and #(traceTable.pos - traceTable.startpos) <= minDistance then
		if traceTable.enthit.IsStunned ~= nil then
			DebugDrawLine(traceTable.startpos, traceTable.pos, 255, 0, 0, false, 1)
		else
			DebugDrawLine(traceTable.startpos, traceTable.pos, 0, 0, 0, false, 1)
		end
	else
		DebugDrawLine(startPos + Vector(0, 0, 100), startPos + forward * minDistance + Vector(0, 0, 100), 0, 0, 0, false, 1)
	end]]
end

function Beams:UpdateParticle(beamSegment)

end

function Beams:OnBeamsThink(player)
	local heroEntity = player:GetAssignedHero()
	local origin = heroEntity:GetAbsOrigin()
	player.beam.direction = heroEntity:GetForwardVector():Normalized()
	player.beam.startPos = origin + player.beam.direction * 100
	Beams:RecalcBeamSegment(player.beam)
end

function Beams:OnBeamStop(player)
	if player.beam ~= nil then
		player.beam.destroy(false)
		player.beam = nil
	end
end

function Beams:Interrupt(player)
	if player.beam ~= nil then
		player.beam.destroy(true)
		player.beam = nil
	end
	local heroEntity = player:GetAssignedHero()
	Timers:CreateTimer(0.02, function()
		heroEntity:AddNewModifier(heroEntity, nil, "modifier_knockdown", { duration = 0.8 })
	end)
end

function Beams:BeamsTrace(pBeamSegment)
	local pStart = pBeamSegment.startPos
	local pEnd = pBeamSegment.endPos
	local pxMin, pxMax = pStart.x, pEnd.x
	if pEnd.x < pStart.x then
		pxMin, pxMax = pEnd.x, pStart.x
	end
	local pK = (pEnd.y - pStart.y) / (pEnd.x - pStart.x)
	local pB = -pK*pStart.x + pStart.y

	local minDistance = BEAM_MAX_LENGTH
	local result = nil
	for _, beamSegment in pairs(Beams.beamSegments) do
		if beamSegment ~= pBeamSegment then
			local startPos = beamSegment.startPos
			local endPos = beamSegment.endPos
			local xMin, xMax = startPos.x, endPos.x
			if endPos.x < startPos.x then
				xMin, xMax = endPos.x, startPos.x
			end
			local k = (endPos.y - startPos.y) / (endPos.x - startPos.x)
			local b = -k*startPos.x + startPos.y
			local intersectX = (b - pB) / (pK - k)
			if intersectX > pxMin and intersectX < pxMax and intersectX > xMin and intersectX < xMax then
				local intersectPoint = Vector(intersectX, pK*intersectX + pB, pStart.z)
				local distance = (pStart - intersectPoint):Length2D()
				if result == nil or distance < minDistance then
					result = { segment = beamSegment, point = intersectPoint, distance = distance }
					minDistance = distance
				end
			end
		end
	end
	return result
end

function Beams:EntitiesTrace(beamSegment)
	local traceTable = {
		startpos = beamSegment.startPos + Vector(0, 0, 30),
		endpos = beamSegment.endPos + Vector(0, 0, 30),
		ignore = beamSegment.player:GetAssignedHero(),
		min = Vector(-BEAM_COLLISION_WIDTH / 2, -BEAM_COLLISION_WIDTH / 2, -25),
		max = Vector(BEAM_COLLISION_WIDTH / 2, BEAM_COLLISION_WIDTH / 2, 25)
	}
	TraceHull(traceTable)
	if traceTable.hit then
		return { entity = traceTable.enthit, distance = (traceTable.pos - traceTable.startpos):Length2D(), point = traceTable.pos }
	end
	return nil
end

function Beams:TreesTrace(beamSegment)
	local treeDistance = BEAM_MAX_LENGTH
	local step = (beamSegment.endPos - beamSegment.startPos) / BEAM_TREE_DETECTION_STEPS
	local offset = step / 2
	for i = 0, BEAM_TREE_DETECTION_STEPS - 1 do
		local center = beamSegment.startPos + offset + step * i
		local trees = GridNav:GetAllTreesAroundPoint(center, BEAM_TREE_DETECTION_RADIUS, true)
		for _, tree in pairs(trees) do
			local treeOrigin = tree:GetAbsOrigin()
			local h = CalcDistanceToLineSegment2D(treeOrigin, beamSegment.startPos, beamSegment.endPos)
			if h <= BEAM_COLLISION_WIDTH then
				local distance = (treeOrigin - beamSegment.startPos):Length2D()
				if distance < treeDistance then
					treeDistance = distance
				end
			end
		end
		if treeDistance < BEAM_MAX_LENGTH then
			return { distance = treeDistance, point = beamSegment.startPos + beamSegment.direction * treeDistance }
		end
	end
	return nil
end