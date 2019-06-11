require("libraries/timers")

local BLINKING_DURATION = 4.0
local BLINK_PERIOD = 0.2

local BLINK_PHASE_HIDDEN = 0
local BLINK_PHASE_SHOWN = 1


if HelperModifierShield == nil then
	HelperModifierShield = class({})
end

function HelperModifierShield:StdOnDestroy(modifier)
	if IsServer() then
		modifier:GetParent().shieldElements[modifier.index] = nil
		if modifier.particleIndex ~= nil then
			ParticleManager:DestroyParticle(modifier.particleIndex, false)
		end
		if modifier.blinkTimer ~= nil then
			Timers:RemoveTimer(modifier.blinkTimer)
		end
	end
end

function HelperModifierShield:StdOnCreated(modifier, kv, element, particle)
	modifier.index = kv.index
	if IsServer() then
		modifier:GetParent().shieldElements[modifier.index] = element

		modifier.particleIndex = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, modifier:GetParent())
		ParticleManager:SetParticleControl(modifier.particleIndex, 1, Vector(kv.circleRadius, 0, 0))
		ParticleManager:SetParticleControl(modifier.particleIndex, 2, Vector(1, 0, 0))
		modifier:AddParticle(modifier.particleIndex, false, false, -1, false, false)

		HelperModifierShield:InitBlinking(modifier, kv.duration)
	end
end

function HelperModifierShield:InitBlinking(modifier, duration)
	modifier.blinkPhase = BLINK_PHASE_SHOWN
	modifier.blinkTimer = Timers:CreateTimer(duration - BLINKING_DURATION, function()
		local particleControlValue
		if modifier.blinkPhase == BLINK_PHASE_HIDDEN then
			modifier.blinkPhase = BLINK_PHASE_SHOWN
			particleControlValue = 1
		else
			modifier.blinkPhase = BLINK_PHASE_HIDDEN
			particleControlValue = 0
		end

		ParticleManager:SetParticleControl(modifier.particleIndex, 2, Vector(particleControlValue, 0, 0))

		return BLINK_PERIOD
	end)
end