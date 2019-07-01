var keybindTable = {
	"+rm_key_q" : "rm_pick_water",
	"+rm_key_w" : "rm_pick_life",
	"+rm_key_e" : "rm_pick_shield",
	"+rm_key_r" : "rm_pick_cold",
	"+rm_key_a" : "rm_pick_lightning",
	"+rm_key_s" : "rm_pick_death",
	"+rm_key_d" : "rm_pick_earth",
	"+rm_key_f" : "rm_pick_fire",
	"+rm_key_ctrl" : "rm_stop_move",
	"+rm_key_space"   : null,
	"+rm_key_tab"     : null,
	"+rm_key_shift"   : null,

	"rm_mouse_left_down"   : "rm_move_to_down",
	"rm_mouse_left_up"	   : "rm_move_to_up",
	"rm_mouse_right_down"  : "rm_directed_cast_down",
	"rm_mouse_right_up"	   : "rm_directed_cast_up",
	"rm_mouse_middle_down" : "rm_self_cast_down",
	"rm_mouse_middle_up"   : "rm_self_cast_up"
};
var keyCaptureCallback = null;
var onRebindCallback = null;

for (var key in keybindTable) {
	if(key[0] == '+') {
		addEvent(key);
	}
}

function getKey(table, value) {
	for (var key in table) {
		if (table[key] == value) {
			return key;
		}
	}
	return null;
}

function addEvent(eventName) {
	Game.AddCommand(eventName, function() { onKeyEvent(eventName); }, "", 0);
}

function setOnRebindCallback(callback) {
	onRebindCallback = callback;
}

function onKeyEvent(eventName) {
	if(!keybindTable.hasOwnProperty(eventName)) {
		return;
	}
	if(keyCaptureCallback != null && keyCaptureCallback(eventName)) {
		return;
	}
	var actionName = keybindTable[eventName];
	if(actionName == null) {
		return;
	}
	var playerID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer(actionName, { "playerID" : playerID });
}

function rebind(eventName, actionName) {
	if(!(eventName in keybindTable)) {
		return;
	}
	var oldActionName = keybindTable[eventName];
	var oldEventName = getKey(keybindTable, actionName);

	keybindTable[eventName] = actionName;
	if(oldEventName != null) {
		keybindTable[oldEventName] = oldActionName;
	}

	if(onRebindCallback != null) {
		onRebindCallback();
	}
}

function startKeyCapture(callback) {
	keyCaptureCallback = callback;
}

function endKeyCapture() {
	keyCaptureCallback = null;
}


GameEvents.Subscribe("rm_settings_holder", onSettingsHolderCreated);
GameEvents.SendCustomGameEventToServer("rm_send_settings", { "playerID" : Players.GetLocalPlayer() });

var settingsHolderIndex = null;

function onSettingsHolderCreated(params) {
	settingsHolderIndex = params.index;
	$.Schedule(0.02, tryGetSettings);
}

function tryGetSettings() {
	var stackCount = Buffs.GetStackCount(settingsHolderIndex, 2);
	if (stackCount == 0) {
		$.Schedule(0.02, tryGetSettings);
		return;
	}
}