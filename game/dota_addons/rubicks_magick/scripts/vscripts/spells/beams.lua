if Beams == nil then
	Beams = class({})
end

BEAM_MAX_LENGTH = 2500
BEAM_COLLISION_WIDTH = 80
BEAM_TREE_DETECTION_STEPS = 5
BEAM_TREE_DETECTION_RADIUS = (BEAM_MAX_LENGTH / BEAM_TREE_DETECTION_STEPS) / 2

BEAM_MIN_BEAMS_ANGLE_DEG = 8
BEAM_COS_MIN_BEAMS_ANGLE = math.cos(math.rad(BEAM_MIN_BEAMS_ANGLE_DEG))

BEAMS_THINK_PERIOD = 0.01

function Beams:Precache(context)	
	LinkLuaModifier("modifier_beam_cast", "modifiers/modifier_beam_cast.lua", LUA_MODIFIER_MOTION_NONE)
	PrecacheResource("particle_folder", "particles/beams/life_beam", context)
	PrecacheResource("particle_folder", "particles/beams/death_beam", context)
end

function Beams:Init()
	Beams.beamSegments = {}
	GameRules:GetGameModeEntity():SetThink(Dynamic_Wrap(Beams, "OnBeamsThink"), "BeamsThink", BEAMS_THINK_PERIOD)
end

function Beams:PlayerConnected(player)
end


function Beams:StartLifeBeam(player, pickedElements)
	local caster = player:GetAssignedHero()

	local lifeCount = table.count(pickedElements, ELEMENT_LIFE)
	local mul = ({ 22.29, 31.96, 38.87 })[lifeCount]
	local pow = ({ 0.50,  0.39,  0.50  })[lifeCount]

	local color = Vector(50, 255, 50)
	local addFunc = nil
	local additionalEffectTable = {
		[ELEMENT_LIFE] = {
			[ELEMENT_LIFE] = {
				[ELEMENT_FIRE] = function()
					color = Vector(255, 140, 50)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 3.92 * math.pow(power, 0.45), true) end
				end,
				[ELEMENT_COLD] = function()
					color = Vector(120, 170, 255)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 3.04 * math.pow(power, 0.4), true) end
				end,
				[ELEMENT_WATER] = function()
					color = Vector(50, 120, 250)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_WATER, 1, true) end
				end
			},
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function()
					color = Vector(150, 150, 180)
					addFunc = function(target, power)
						Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 3.75 * math.pow(power, 0.55), false, 1.0)
						Spells:ApplyElementDamage(target, caster, ELEMENT_WATER, 3.75 * math.pow(power, 0.55), false, 1.0)
					end
				end,
				[DEFAULT] = function()
					color = Vector(50, 120, 250)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_WATER, 1, true) end
				end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE] = function()
					color = Vector(255, 140, 50)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 4.98 * math.pow(power, 0.53), true) end
				end,
				[EMPTY] = function()
					color = Vector(255, 140, 50)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 3.83 * math.pow(power, 0.47), true) end
				end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD] = function()
					color = Vector(120, 170, 255)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 3.9 * math.pow(power, 0.49), true) end
				end,
				[EMPTY] = function()
					color = Vector(120, 170, 255)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 2.32 * math.pow(power, 0.6), true) end
				end
			}
		}
	}
	local additionalEffectFunc = table.serialRetrieve(additionalEffectTable, pickedElements)
	if additionalEffectFunc ~= nil then
		additionalEffectFunc()
	end
	local effectFunction = function(target, power)
		Spells:Heal(target, caster, mul * math.pow(power, pow))
		if addFunc ~= nil then
			addFunc(target, power)
		end
	end
	Beams:CreateBeam(player, "particles/beams/life_beam/life_beam.vpcf", color, ELEMENT_LIFE, effectFunction)
end

function Beams:StartDeathBeam(player, pickedElements)
	local caster = player:GetAssignedHero()

	local deathCount = table.count(pickedElements, ELEMENT_DEATH)
	local mul = ({ 17.9, 25.8, 30.5 })[deathCount]
	local pow = ({ 0.50, 0.49, 0.53 })[deathCount]
	
	local color = Vector(200, 0, 0)
	local addFunc = nil
	local additionalEffectTable = {
		[ELEMENT_DEATH] = {
			[ELEMENT_DEATH] = {
				[ELEMENT_FIRE]  = function()
					color = Vector(255, 100, 0)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 2.75 * math.pow(power, 0.96), true) end
				end,
				[ELEMENT_COLD]  = function()
					color = Vector(130, 200, 240)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 2.19 * math.pow(power, 0.62), true) end
				end,
				[ELEMENT_WATER] = function()
					color = Vector(20, 80, 220)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_WATER, 1, true) end
				end
			},
			[ELEMENT_WATER] = {
				[ELEMENT_FIRE] = function()
					color = Vector(160, 160, 170)
					addFunc = function(target, power)
						Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 4.05 * math.pow(power, 0.49), false, 1.0)
						Spells:ApplyElementDamage(target, caster, ELEMENT_WATER, 4.05 * math.pow(power, 0.49), false, 1.0)
					end
				end,
				[DEFAULT] = function()
					color = Vector(20, 80, 220)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_WATER, 1, true) end
				end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE] = function()
					color = Vector(255, 100, 0)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 4.97 * math.pow(power, 0.52), true) end
				end,
				[EMPTY] = function()
					color = Vector(255, 100, 0)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 3.3 * math.pow(power, 0.57), true) end
				end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD] = function()
					color = Vector(130, 200, 240)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 3.9 * math.pow(power, 0.48), true) end
				end,
				[EMPTY] = function()
					color = Vector(130, 200, 240)
					addFunc = function(target, power) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 2.6 * math.pow(power, 0.72), true) end
				end
			}
		}
	}
	local additionalEffectFunc = table.serialRetrieve(additionalEffectTable, pickedElements)
	if additionalEffectFunc ~= nil then
		additionalEffectFunc()
	end
	local effectFunction = function(target, power)
		Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, mul * math.pow(power, pow))
		if addFunc ~= nil then
			addFunc(target, power)
		end
	end
	Beams:CreateBeam(player, "particles/beams/death_beam/death_beam.vpcf", color, ELEMENT_DEATH, effectFunction)
end

function Beams:CreateBeam(player, particleName, color, mainElement, effectFunction)
	local heroEntity = player:GetAssignedHero()
	local spellCastTable = {
		castType = CAST_TYPE_CONTINUOUS,
		duration = 7.0,
		slowMovePercentage = 30,
		turnDegsPerSec = 60.0,
		castingGesture = ACT_DOTA_CHANNEL_ABILITY_5,
		castingGestureTranslate = "black_hole",
		castingGestureRate = 1.5,
		endFunction = function(player) Beams:OnBeamStop(player) end,
		beams_Power = 1,
		beams_EffectFunction = effectFunction
	}
	Spells:StartCasting(player, spellCastTable)
	player.spellCast.beams_Modifier = heroEntity:AddNewModifier(heroEntity, nil, "modifier_beam_cast", {})
	
	local origin = heroEntity:GetAbsOrigin()
	local direction = heroEntity:GetForwardVector():Normalized()
	local startPos = origin + direction * 120
	player.beam = Beams:CreateBeamSegment(player, startPos, direction, nil, mainElement, particleName, color)
end

function Beams:CreateBeamSegment(player, startPos, direction, parentSegment, mainElement, particleName, color)
	local beamSegment = {
		player = player,
		parent = parentSegment,
		mainElement = mainElement,
		particleName = particleName or parentSegment.particleName,
		color = color or parentSegment.color,
		startPos = startPos,
		direction = direction,
		endPos = startPos,
		creationTime = GameRules:GetGameTime()
	}
	beamSegment.particle = ParticleManager:CreateParticle(beamSegment.particleName, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(beamSegment.particle, 3, beamSegment.color)
	Beams:UpdateParticle(beamSegment)
	beamSegment.destroy = function(isInterrupt)
		if beamSegment.child ~= nil then
			beamSegment.child.destroy(isInterrupt)
		end
		ParticleManager:SetParticleControl(beamSegment.particle, 4, Vector(isInterrupt and 1 or 0, 0, 0))
		ParticleManager:DestroyParticle(beamSegment.particle, false)
		local index = table.indexOf(Beams.beamSegments, beamSegment)
		table.remove(Beams.beamSegments, index)
	end
	Timers:CreateTimer(0.01, function() Beams:RecalcBeamSegment(beamSegment) end)
	
	table.insert(Beams.beamSegments, beamSegment)
	return beamSegment
end

function Beams:UpdateParticle(beamSegment)
	if beamSegment ~= nil and beamSegment.player.spellCast ~= nil then
		ParticleManager:SetParticleControl(beamSegment.particle, 0, beamSegment.startPos + Vector(0, 0, 100))
		ParticleManager:SetParticleControl(beamSegment.particle, 1, beamSegment.endPos + Vector(0, 0, 100))
		ParticleManager:SetParticleControl(beamSegment.particle, 2, Vector(beamSegment.player.spellCast.beams_Power * 0.25, 0, 0))
	end
end

function Beams:OnBeamsThink()
	local beamsToRecalc = {}
	for playerID = 0, DOTA_MAX_PLAYERS - 1 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil and player.spellCast ~= nil and player.beam ~= nil then
			local beam = player.beam
			local heroEntity = player:GetAssignedHero()
			local origin = heroEntity:GetAbsOrigin()
			beam.direction = heroEntity:GetForwardVector():Normalized()
			beam.startPos = origin + beam.direction * 120
			beam.endPos = beam.startPos + beam.direction * BEAM_MAX_LENGTH
			player.spellCast.beams_Modifier:ResetTarget()
			table.insert(beamsToRecalc, beam)
		end
	end
	for _, beam in pairs(beamsToRecalc) do
		Beams:RecalcBeamSegment(beam)
	end
	return BEAMS_THINK_PERIOD
end

function Beams:OnBeamStop(player)
	if player.beam ~= nil then
		player.beam.destroy(false)
		player.beam = nil
	end
	player.spellCast.beams_Modifier:Destroy()
end

function Beams:Interrupt(player)
	if player.beam ~= nil then
		Beams:UpdateParticle(player.beam)
		player.beam.destroy(true)
		player.beam = nil
	end
	local heroEntity = player:GetAssignedHero()
	Timers:CreateTimer(0.02, function() Spells:StopCasting(player) end)
	Timers:CreateTimer(0.1, function() 
		heroEntity:AddNewModifier(heroEntity, nil, "modifier_knockdown", { duration = 1.5 })
	end)
end

function Beams:RecalcBeamSegment(beamSegment)
	if beamSegment == nil or beamSegment.player.spellCast == nil then
		return
	end
	if MagicShield:DoesPointOverlapShields(beamSegment.startPos) then
		beamSegment.endPos = beamSegment.startPos + beamSegment.direction * 50
		Beams:Interrupt(beamSegment.player)
		return
	end

	local hitList = {}
	table.insert(hitList, Beams:EntitiesTrace(beamSegment))
	table.insert(hitList, Beams:TreesTrace(beamSegment))
	table.insert(hitList, Beams:BeamsTrace(beamSegment))
	table.insert(hitList, MagicShield:TraceLine(beamSegment.startPos, beamSegment.endPos))

	local noChild = true
	--local noEntityTarget = true
	local beamTarget = nil
	local minDistance = BEAM_MAX_LENGTH
	local closestHit = nil
	for _, hit in pairs(hitList) do
		if closestHit == nil or hit.distance < minDistance then
			minDistance = hit.distance
			closestHit = hit
		end
	end
	if closestHit ~= nil then
		beamSegment.endPos = closestHit.point
		if closestHit.reflectedDirection ~= nil then		-- hit magic shield
			noChild = false
			if beamSegment.direction:Dot(-closestHit.reflectedDirection) >= BEAM_COS_MIN_BEAMS_ANGLE then
				Beams:Interrupt(beamSegment.player)
				return
			else
				local childStart = beamSegment.endPos + closestHit.reflectedDirection * 0.05
				if beamSegment.child == nil then
					print("new child")
					beamSegment.child = Beams:CreateBeamSegment(beamSegment.player, childStart, closestHit.reflectedDirection, beamSegment, beamSegment.mainElement)
				else
					beamSegment.child.direction = closestHit.reflectedDirection
					beamSegment.child.startPos = childStart
					beamSegment.child.endPos = childStart + closestHit.reflectedDirection * BEAM_MAX_LENGTH
					Beams:RecalcBeamSegment(beamSegment.child)
				end
			end
		elseif closestHit.segment ~= nil then	-- hit another beam
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
				local olderSegment, youngerSegment = beamSegment, closestHit.segment
				if closestHit.segment.creationTime < beamSegment.creationTime then
					olderSegment, youngerSegment = closestHit.segment, beamSegment
				end
				local childDirection = (beamSegment.direction + closestHit.segment.direction):Normalized()
				beamSegment.endPos = closestHit.point - beamSegment.direction * 0.05
				closestHit.segment.endPos = closestHit.point - closestHit.segment.direction * 0.05
				Beams:RecalcBeamSegment(youngerSegment)
				local childStart = olderSegment.endPos + childDirection * 0.05
				if olderSegment.child == nil then
					olderSegment.child = Beams:CreateBeamSegment(olderSegment.player, childStart, childDirection, olderSegment, olderSegment.mainElement)
					olderSegment.child.secondParent = youngerSegment
				else
					olderSegment.child.direction = childDirection
					olderSegment.child.startPos = childStart
					olderSegment.child.endPos = childStart + childDirection * BEAM_MAX_LENGTH
					Beams:RecalcBeamSegment(olderSegment.child)
				end
			end
		elseif closestHit.entity ~= nil and closestHit.entity.IsStunned ~= nil then 	-- hit an entity. IsStunned ~= nil is check for NPC
			beamTarget = closestHit.entity
		end
	end

	Beams:UpdateParticle(beamSegment)
	beamSegment.player.spellCast.beams_Modifier:SetTarget(beamTarget)
	if beamSegment.child ~= nil and noChild then
		beamSegment.child.destroy(false)
		beamSegment.child = nil
	end
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
		local isNotParent = beamSegment ~= pBeamSegment.parent and pBeamSegment ~= beamSegment.parent
		local isNotSecondParent = beamSegment ~= pBeamSegment.secondParent and pBeamSegment ~= beamSegment.secondParent
		if beamSegment ~= pBeamSegment and isNotParent and isNotSecondParent then
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
	local units = Util:FindUnitsInLine(beamSegment.startPos, beamSegment.endPos, BEAM_COLLISION_WIDTH, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	local resultUnit = nil
	local minDistance = BEAM_MAX_LENGTH
	for _, unit in pairs(units) do
		local distance = (unit:GetAbsOrigin() - beamSegment.startPos):Length2D()
		if distance < minDistance then
			minDistance = distance
			resultUnit = unit
		end
	end
	if resultUnit ~= nil then
		return { entity = resultUnit, distance = minDistance, point = beamSegment.startPos + beamSegment.direction * minDistance }
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