local PLACEMENT_DISTANCE = 190
local CLEAR_SPACE_RADIUS = 80

if Placer == nil then
    Placer = class({})
    Placer.onKilledCallbacks = {}
end

function Placer:Init() 
    ListenToGameEvent("entity_killed", Dynamic_Wrap(Placer, "OnEntityKilled"), self)
end

function Placer:OnEntityKilled(keys)
    local unit = EntIndexToHScript(keys.entindex_killed)
    local callback = Placer.onKilledCallbacks[unit]
    if callback ~= nil then
        local isQuietKill = unit.isQuietKill or false
        unit.isQuietKill = nil
        callback(unit, isQuietKill)
        Placer.onKilledCallbacks[unit] = nil
    end
end

function Placer:PlaceDummiesInFrontOfCaster(caster, number, anglePerUnit, onKilledCallback)
    local origin = caster:GetAbsOrigin()
    local forward = caster:GetForwardVector()

    local initialShiftRot = QAngle(0, -(number - 1) * 0.5 * anglePerUnit, 0)
    local deltaShiftRot = QAngle(0, anglePerUnit, 0)

    forward = RotatePosition(Vector(0, 0, 0), initialShiftRot, forward)

    local result = {}
    for i = 1, number do
        local position = origin + forward * PLACEMENT_DISTANCE

        Placer:ClearSpace(position, CLEAR_SPACE_RADIUS, result)

        local unit = Util:CreateDummyWithoutModifier(position)
        unit:SetForwardVector(forward)
        unit.isPlaceable = true

        if onKilledCallback ~= nil then
            Placer.onKilledCallbacks[unit] = onKilledCallback
        end        
        table.insert(result, unit)
        forward = RotatePosition(Vector(0, 0, 0), deltaShiftRot, forward)
    end
    return result
end

function Placer:ClearSpace(position, radius, ignoreUnits)
    local units = Util:FindUnitsInRadius(position, radius)
    for _, unit in pairs(units) do
        if unit.isPlaceable and not table.indexOf(ignoreUnits, unit) then
            Placer:KillQuietly(unit)
        end
    end
end

function Placer:KillQuietly(unit)
    unit.isQuietKill = true
    unit:Kill(nil, nil)
end