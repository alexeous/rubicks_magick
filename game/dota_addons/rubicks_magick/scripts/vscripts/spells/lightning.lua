if Lightning == nil then
	Lightning = class({})
end

LIGHTNING_DISTANCES = { 250, 400, 600 }

function Lightning:Precache(context)	
	LinkLuaModifier("modifier_lightning_stun", "modifiers/modifier_lightning_stun.lua", LUA_MODIFIER_MOTION_NONE)
	PrecacheResource("particle_folder", "particles/lightning", context)
end

function Lightning:PlayerConnected(player)
end


function Lightning:DirectedLightning(player, pickedElements)
	local caster = player:GetAssignedHero()
	if caster:HasModifier("modifier_wet") then
		Spells:WetCastLightning(caster)
		return
	end
	local color = Vector(160, 80, 255)
	local additionalEffectFunc = nil
	local additionalEffectTable = {
		[ELEMENT_LIGHTNING] = {
			[ELEMENT_LIGHTNING] = {
				[ELEMENT_LIFE] = function()
					additionalEffectFunc = function(target) Spells:Heal(target, caster, 75) end
					color = Vector(97, 255, 65)
				end,
				[ELEMENT_DEATH] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52) end
					color = Vector(200, 10, 10)
				end,
				[ELEMENT_FIRE] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true) end
					color = Vector(255, 135, 70)
				end,
				[ELEMENT_COLD] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true) end
					color = Vector(113, 190, 240)
				end
			},
			[ELEMENT_LIFE] = {
				[ELEMENT_LIFE] = function()
					additionalEffectFunc = function(target) Spells:Heal(target, caster, 106) end
					color = Vector(97, 255, 65)
				end,
				[ELEMENT_FIRE] = function()
					additionalEffectFunc = function(target) 
						Spells:Heal(target, caster, 75)
						Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true)
					end
					color = Vector(255, 135, 70)
				end,
				[ELEMENT_COLD] = function()
					additionalEffectFunc = function(target) 
						Spells:Heal(target, caster, 75)
						Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true) 
					end
					color = Vector(113, 190, 240)
				end,
				[EMPTY] = function()
					additionalEffectFunc = function(target) Spells:Heal(target, caster, 75) end
					color = Vector(97, 255, 65)
				end
			},
			[ELEMENT_DEATH] = {
				[ELEMENT_DEATH] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 74) end
					color = Vector(200, 10, 10)
				end,
				[ELEMENT_FIRE] = function()
					additionalEffectFunc = function(target) 
						Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52)
						Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true)
					end
					color = Vector(255, 135, 70)
				end,
				[ELEMENT_COLD] = function()
					additionalEffectFunc = function(target) 
						Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52)
						Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true) 
					end
					color = Vector(113, 190, 240)
				end,
				[EMPTY] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_DEATH, 52) end
					color = Vector(200, 10, 10)
				end
			},
			[ELEMENT_FIRE] = {
				[ELEMENT_FIRE] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 21, true) end
					color = Vector(255, 135, 70)
				end,
				[EMPTY] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_FIRE, 15, true) end
					color = Vector(255, 135, 70)
				end
			},
			[ELEMENT_COLD] = {
				[ELEMENT_COLD] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 26, true) end
					color = Vector(113, 190, 240)
				end,
				[EMPTY] = function()
					additionalEffectFunc = function(target) Spells:ApplyElementDamage(target, caster, ELEMENT_COLD, 18, true) end
					color = Vector(113, 190, 240)
				end
			}
		}
	}
	local applyAddEffectFunc = table.serialRetrieve(additionalEffectTable, pickedElements)
	if applyAddEffectFunc ~= nil then
		applyAddEffectFunc()
	end
	local lightningCount = table.count(pickedElements, ELEMENT_LIGHTNING)
	local lightningDamage = ({ 42, 60, 73 })[lightningCount]
	local spellCastTable = {
		castType = CAST_TYPE_INSTANT,
		duration = 1.5,
		dontMoveWhileCasting = true,
		castingGesture = ACT_DOTA_CAST_ABILITY_3,
		castingGestureRate = 0.5,
		thinkFunction = function(player) Lightning:OnDirectedLightningThink(player) end,
		thinkPeriod = 0.4,
		lightning_Color = color,
		lightning_IsLife = table.indexOf(pickedElements, ELEMENT_LIFE) ~= nil,
		lightning_IsDeath = table.indexOf(pickedElements, ELEMENT_DEATH) ~= nil,
		lightning_Distance = LIGHTNING_DISTANCES[lightningCount],
		lightning_StrikesLeft = 3,
		lightning_EffectFunction = Lightning:MakeEffectFunction(caster, lightningDamage, additionalEffectFunc)
	}
	Spells:StartCasting(player, spellCastTable)
end

function Lightning:OmniLightning(player, pickedElements)
	-------- TODO ---------
end

function Lightning:MakeEffectFunction(caster, lightningDamage, additionalEffectFunc)
	return function(target)
		Spells:ApplyElementDamage(target, caster, ELEMENT_LIGHTNING, lightningDamage)
		if additionalEffectFunc ~= nil then
			additionalEffectFunc(target)
		end
		target:AddNewModifier(caster, nil, "modifier_lightning_stun", { duration = 0.2 })
	end
end

function Lightning:CreateParticle(player, startPos, endPos, noTarget)
	local particleName = player.spellCast.lightning_IsDeath and "particles/lightning/lightning_death.vpcf" or "particles/lightning/lightning.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, startPos + Vector(0, 0, 100))
	ParticleManager:SetParticleControl(particle, 1, endPos + Vector(0, 0, 100))
	ParticleManager:SetParticleControl(particle, 3, player.spellCast.lightning_Color)
	ParticleManager:SetParticleControl(particle, 4, Vector(noTarget and 0 or 1, player.spellCast.lightning_IsLife and 1 or 0, 0))
end

function Lightning:ChainLightning(player, startUnit, maxDistance, startPos)
	startPos = startPos or startUnit:GetAbsOrigin()
	local effectFunc = player.spellCast.lightning_EffectFunction
	local heroEntity = player:GetAssignedHero()	
	local ignoreUnits = { startUnit, heroEntity }
	local units = Util:FindUnitsInRadius(startUnit:GetAbsOrigin(), maxDistance, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	local secondaryStartUnits = {}
	for _, unit in pairs(units) do
		if table.indexOf(ignoreUnits, unit) == nil then
			table.insert(ignoreUnits, unit)
			table.insert(secondaryStartUnits, unit)
			effectFunc(unit)
			Lightning:CreateParticle(player, startPos, unit:GetAbsOrigin())
		end
	end
	for _, secondaryStartUnit in pairs(secondaryStartUnits) do
		local secondaryUnits = Util:FindUnitsInRadius(secondaryStartUnit:GetAbsOrigin(), maxDistance * 0.7, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
		for _, secondaryUnit in pairs(secondaryUnits) do
			if table.indexOf(ignoreUnits, secondaryUnit) == nil then
				table.insert(ignoreUnits, secondaryUnit)
				effectFunc(secondaryUnit)
				Lightning:CreateParticle(player, secondaryStartUnit:GetAbsOrigin(), secondaryUnit:GetAbsOrigin())
			end
		end
	end
end

function Lightning:OnDirectedLightningThink(player)
	player.spellCast.thinkPeriod = 0.25
	
	local heroEntity = player:GetAssignedHero()
	local forwardVec = heroEntity:GetForwardVector()
	local lightningDistance = player.spellCast.lightning_Distance
	local startPos = heroEntity:GetAbsOrigin() + forwardVec * 160
	local endPos = startPos + forwardVec * lightningDistance
	
	local units = Util:FindUnitsInLine(startPos, endPos, 150, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
	table.remove(units, table.indexOf(units, heroEntity))
	local minDistance = math.huge
	local closestUnit = nil
	for _, unit in pairs(units) do
		local distance = (unit:GetAbsOrigin() - startPos):Length2D()
		if distance < minDistance then
			closestUnit = unit
			minDistance = distance
		end
	end
	if closestUnit == nil then
		local randomOffset = Vector(math.random(-50, 50), math.random(-50, 50), math.random(-100, 100))
		Lightning:CreateParticle(player, startPos, endPos + randomOffset, true)
	else
		player.spellCast.lightning_EffectFunction(closestUnit)
		Lightning:CreateParticle(player, startPos, closestUnit:GetAbsOrigin())
		Lightning:ChainLightning(player, closestUnit, lightningDistance * 0.7)
	end

	player.spellCast.lightning_StrikesLeft = player.spellCast.lightning_StrikesLeft - 1
	if player.spellCast.lightning_StrikesLeft <= 0 then
		player.spellCast.thinkFunction = nil
	end
end