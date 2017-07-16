if OmniElementSprays == nil then
	OmniElementSprays = class({})
end

function OmniElementSprays:Precache(context)

end

function OmniElementSprays:PlayerConnected(player)

end


function OmniElementSprays:OmniSteamSpray(player, modifierElement)
	-------- TODO ---------
end

function OmniElementSprays:OmniWaterSpray(player, power)
	-------- TODO ---------
end

function OmniElementSprays:OmniFireSpray(player, power)
	-------- TODO ---------
end

function OmniElementSprays:OmniColdSpray(player, power)
	Spells:ApplyElementDamage(player:GetAssignedHero(), player:GetAssignedHero(), ELEMENT_COLD, 91, true)
	-------- TODO ---------
end
