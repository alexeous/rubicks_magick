require("modifiers/helper_modifier_shield")

if modifier_shield_earth == nil then
	modifier_shield_earth = class({})
end

function modifier_shield_earth:IsDebuff()
	return false
end

function modifier_shield_earth:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_shield_earth:OnDestroy()
	HelperModifierShield:StdOnDestroy(self)
end

function modifier_shield_earth:OnCreated(kv)
	HelperModifierShield:StdOnCreated(self, kv, ELEMENT_EARTH, "particles/shield_circles/shield_circle_earth.vpcf")
	if IsClient() then
		local file = io.open("rubicks_magick_control_config", "r")
		if file == nil then 
			print("No file") 
		else
			print("Reading:", file:read())
			file:close()
		end
		file = io.open("rubicks_magick_control_config", "w")
		if file == nil then 
			print("Failed to open file")
		else
			file:write("Hallo!")
			file:close()
		end
		--print("Reading:", FileToString("rubicks_magick_control_config"))
		--StringToFile("rubicks_magick_control_config", "Hallo!")
	end
end

function modifier_shield_earth:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_shield_earth:GetModifierMoveSpeedBonus_Percentage(params)
	return -10.0
end