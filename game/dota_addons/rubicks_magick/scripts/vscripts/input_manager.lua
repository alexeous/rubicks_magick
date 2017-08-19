
if InputManager == nil then
    InputManager = class({})
end

INPUT_MANAGER_KEYS = {
    "rm_key_q", "rm_key_w", "rm_key_e", "rm_key_r",
    "rm_key_a", "rm_key_s", "rm_key_d", "rm_key_f",
    "rm_key_space", 
    "rm_key_control", 
    "rm_key_tab",
    "rm_key_shift", 
    "rm_key_alt"
}

INPUT_MANAGER_MOUSE_EVENTS = {
    "rm_mouse_left_down",
    "rm_mouse_left_up",
    "rm_mouse_right_down",
    "rm_mouse_right_up",
    "rm_mouse_middle_down",
    "rm_mouse_middle_up"
}

INPUT_MANAGER_ACTIONS = {
    move_to_down = Dynamic_Wrap(MoveController, "OnMoveToKeyDown"),
    move_to_up = Dynamic_Wrap(MoveController, "OnMoveToKeyUp"),
    stop_move = Dynamic_Wrap(MoveController, "OnStopMoveKeyDown"),
    directed_cast_down = Dynamic_Wrap(Spells, "OnDirectedCastKeyDown"),
    directed_cast_up = Dynamic_Wrap(Spells, "OnDirectedCastKeyUp"),
    self_cast_down = Dynamic_Wrap(Spells, "OnSelfCastKeyDown"),
    self_cast_up = Dynamic_Wrap(Spells, "OnSelfCastKeyUp"),
    pick_water     = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_WATER) end,
    pick_life      = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_LIFE) end,
    pick_shield    = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_SHIELD) end,
    pick_cold      = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_COLD) end,
    pick_lightning = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_LIGHTNING) end,
    pick_death     = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_DEATH) end,
    pick_earth     = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_EARTH) end,
    pick_fire      = function(keys) Elements:OnPickElement(keys.playerID, ELEMENT_FIRE) end
}

DEFAULT_INPUT_MOUSE_SETTINGS = {
    rm_mouse_left_down = "move_to_down",
    rm_mouse_left_up = "move_to_up",
    rm_mouse_right_down = "directed_cast_down",
    rm_mouse_right_up = "directed_cast_up",
    rm_mouse_middle_down = "self_cast_down",
    rm_mouse_middle_up = "self_cast_up"
}

DEFAULT_INPUT_KEY_SETTINGS = {
    rm_key_control = "stop_move",
    rm_key_q = "pick_water",
    rm_key_w = "pick_life",
    rm_key_e = "pick_shield",
    rm_key_r = "pick_cold",
    rm_key_a = "pick_lightning",
    rm_key_s = "pick_death",
    rm_key_d = "pick_earth",
    rm_key_f = "pick_fire"
}

function InputManager:Init()
    InputManager.mouseSettings = InputManager:InitSettings("rubicks_magick_mouse_settings.cfg", DEFAULT_INPUT_MOUSE_SETTINGS, INPUT_MANAGER_MOUSE_EVENTS)
    InputManager.keySettings = InputManager:InitSettings("rubicks_magick_key_settings.cfg", DEFAULT_INPUT_KEY_SETTINGS, INPUT_MANAGER_KEYS)
end

function InputManager:OnControlEvent(keys)

end

function InputManager:InitSettings(filename, defaultSettings, inputTable)
    local settings = InputManager:LoadSettingsFromFile(filename)
    if settings == nil then
        return InputManager:RestoreDefaultSettings(defaultSettings, filename)
    end
    for k, v in pairs(settings) do
        if table.indexOf(inputTable, k) == nil or INPUT_MANAGER_ACTIONS[v] == nil then
            return InputManager:RestoreDefaultSettings(defaultSettings, filename)
        end
    end
    return settings
end

function InputManager:RestoreDefaultSettings(defaultSettings, filename)
    print(filename .. " file is broken. Trying to restore defaults...")
    local settings = table.clone(defaultSettings)
    if not InputManager:SaveSettingsToFile(settings, filename) then
        print("Failed to restore file " .. filename .. "!")
    end
    return settings
end

function InputManager:LoadSettingsFromFile(filename)
    local file, error = io.open(filename, "r")
    if file == nil then
        print("ERROR occured when opening (read) file " .. filename .. ":", error)
        return nil
    end
    local result = {}
    for line in io.lines(file) do
        local splitted = string.gmatch(line, "%S+")
        result[splitted[1]] = splitted[2]
    end
    file:close()
    return result
end

function InputManager:SaveSettingsToFile(settingsTable, filename)
    local file, error = io.open(filename, "w")
    if file == nil then
        print("ERROR occured when opening (write) file " .. filename .. ":", error)
        return false
    end
    for k, v in pairs(settingsTable) do
        file:write(k .. " " .. v)
    end
    file:close()
    return true
end