require("spells/placer")

local KNOCKBACK_AREA_RADIUS = 300
local KNOCKBACK_AREA_ANGLE = 160
local KNOCKBACK_AREA_HALF_COS = math.cos(math.rad(KNOCKBACK_AREA_ANGLE / 2))

LinkLuaModifier("modifier_generic_wall", "modifiers/modifier_generic_wall.lua", LUA_MODIFIER_MOTION_NONE)

if GenericWall == nil then
    GenericWall = class({})
end

function GenericWall:KnockbackAllAwayFromWall(caster)
    local center = caster:GetAbsOrigin()
    local forward = caster:GetForwardVector()
    local units = Util:FindUnitsInRadius(center, KNOCKBACK_AREA_RADIUS)
    for _, unit in pairs(units) do
        if not Spells:IsResistantTo(unit, ELEMENT_EARTH) and 
          Util:AngleBetweenVectorsLessThanAcosOf(forward, unit:GetAbsOrigin() - center, KNOCKBACK_AREA_HALF_COS) then
            MoveController:Knockback(unit, caster, center, KNOCKBACK_AREA_RADIUS)
        end
    end
end

function GenericWall:CreateWallUnits(caster, number, anglePerUnit, immuneToElements, onKilledCallback)
    local walls = Placer:PlaceDummiesInFrontOfCaster(caster, number, anglePerUnit, onKilledCallback)
    for _, wall in pairs(walls) do
        GenericWall:InitWallUnit(wall, immuneToElements)
    end
    return walls
end

function GenericWall:InitWallUnit(wall, immuneToElements)
    wall:AddNewModifier(wall, nil, "modifier_generic_wall", {})
    wall.isWall = true
    
    if immuneToElements ~= nil then
        wall.shieldElements = {}
        for _, element in pairs(immuneToElements) do
            -- only two elements is complete immunity
            table.insert(wall.shieldElements, element)
            table.insert(wall.shieldElements, element)
        end
    end

    return wall
end