ELEMENT_WATER = 1
ELEMENT_LIFE = 2
ELEMENT_SHIELD = 3
ELEMENT_COLD = 4
ELEMENT_LIGHTNING = 5
ELEMENT_DEATH = 6
ELEMENT_EARTH = 7
ELEMENT_FIRE = 8

NUM_ELEMENTS = 8
MAX_PICKED_ELEMENTS = 3

OPPOSITE_ELEMENTS = {}
OPPOSITE_ELEMENTS[ELEMENT_WATER] =     { ELEMENT_LIGHTNING }
OPPOSITE_ELEMENTS[ELEMENT_LIFE] =      { ELEMENT_DEATH }
OPPOSITE_ELEMENTS[ELEMENT_SHIELD] =    { ELEMENT_SHIELD }
OPPOSITE_ELEMENTS[ELEMENT_COLD] =      { ELEMENT_FIRE }
OPPOSITE_ELEMENTS[ELEMENT_LIGHTNING] = { ELEMENT_FIRE, ELEMENT_EARTH }
OPPOSITE_ELEMENTS[ELEMENT_DEATH] = 	   { ELEMENT_LIFE }
OPPOSITE_ELEMENTS[ELEMENT_EARTH] =	   { ELEMENT_LIGHTNING }
OPPOSITE_ELEMENTS[ELEMENT_FIRE] = 	   { ELEMENT_COLD }

if RubicksMagickElements == nil then
	RubicksMagickElements = class({})
end


function RubicksMagickElements:Init()
	Convars:RegisterCommand("+rm_wtr",  function(...) return self:PickElement(ELEMENT_WATER) end, "Picked water element", 0)
	Convars:RegisterCommand("+rm_lif",  function(...) return self:PickElement(ELEMENT_LIFE) end, "Picked life element", 0)
	Convars:RegisterCommand("+rm_shld", function(...) return self:PickElement(ELEMENT_SHIELD) end, "Picked shield element", 0)
	Convars:RegisterCommand("+rm_cld",  function(...) return self:PickElement(ELEMENT_COLD) end, "Picked cold element", 0)
	Convars:RegisterCommand("+rm_ltg",  function(...) return self:PickElement(ELEMENT_LIGHTNING) end, "Picked lightning element", 0)
	Convars:RegisterCommand("+rm_dth",  function(...) return self:PickElement(ELEMENT_DEATH) end, "Picked death element", 0)
	Convars:RegisterCommand("+rm_ert",  function(...) return self:PickElement(ELEMENT_EARTH) end, "Picked earth element", 0)
	Convars:RegisterCommand("+rm_fir",  function(...) return self:PickElement(ELEMENT_FIRE) end, "Picked fire element", 0)

	self.pickedElements = {}
end

function RubicksMagickElements:PlayerConnected(playerID)
	self.pickedElements[playerID] = {}
end

function RubicksMagickElements:PickElement(element)
	local player = Convars:GetCommandClient()
	local playerID = player:GetPlayerID()

	-- trying to find an opposite
	local oppositeIndex = self:FindIndexOfOpposite(playerID, element)
	if oppositeIndex ~= nil then
		self:RemoveFlyingOrb(playerID, oppositeIndex)
		return nil
	end
	
	-- trying to find an empty place for the new element
	for i = 1, MAX_PICKED_ELEMENTS do
		if self.pickedElements[playerID][i] == nil then
			self:AddFlyingOrb(playerID, element, i)
			return nil
		end
	end

	-- shifting the list of the picked elements to free space for the new element
	for i = 1, MAX_PICKED_ELEMENTS - 1 do
		self.pickedElements[playerID][i] = self.pickedElements[playerID][i + 1]
	end
	self:AddFlyingOrb(playerID, element, MAX_PICKED_ELEMENTS)
end

function RubicksMagickElements:FindIndexOfOpposite(playerID, element)
	for index, pickedElement in pairs(self.pickedElements[playerID]) do
		local pickedElementOpposites = OPPOSITE_ELEMENTS[pickedElement]
		for _, opposite in pairs(pickedElementOpposites) do
			if opposite == element then     -- if there is an opposite of this element in the picked elements
				return index
			end
		end
	end
	return nil
end

function RubicksMagickElements:AddFlyingOrb(playerID, element, index)
	self.pickedElements[playerID][index] = element
	Say(nil, tostring(self.pickedElements[playerID][1]) .. " " .. tostring(self.pickedElements[playerID][2]) .. " " .. tostring(self.pickedElements[playerID][3]), false)
	-- TODO: ADD PARTICLE
end

function RubicksMagickElements:RemoveFlyingOrb(playerID, index)
	self.pickedElements[playerID][index] = nil
	Say(nil, tostring(self.pickedElements[playerID][1]) .. " " .. tostring(self.pickedElements[playerID][2]) .. " " .. tostring(self.pickedElements[playerID][3]), false)
	-- TODO: REMOVE PARTICLE
end