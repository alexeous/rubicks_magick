var hideButton = $.GetContextPanel().FindChildTraverse("ControlSettingsHideButton")
var showButton = $.GetContextPanel().FindChildTraverse("ControlSettingsShowButton")
var controlSettingsPanel = $.GetContextPanel().FindChildTraverse("ControlSettings")

function onHideShowClick() {
	hideButton.ToggleClass("invisible");
	showButton.ToggleClass("invisible");
	controlSettingsPanel.ToggleClass("invisible");
	leaveRebindMode();
}

const MOUSE_EVENTS = [ "rm_mouse_left", "rm_mouse_middle", "rm_mouse_right" ];
const ACTIONS = {
	"move" : "rm_move_to",
	"dircast": "rm_directed_cast",
	"selfcast": "rm_self_cast"
}

var controlMove = [
	$.GetContextPanel().FindChildTraverse("ControlSettingsMoveLeft"),
	$.GetContextPanel().FindChildTraverse("ControlSettingsMoveMiddle"),
	$.GetContextPanel().FindChildTraverse("ControlSettingsMoveRight")
];
var controlDirCast = [
	$.GetContextPanel().FindChildTraverse("ControlSettingsDirCastLeft"),
	$.GetContextPanel().FindChildTraverse("ControlSettingsDirCastMiddle"),
	$.GetContextPanel().FindChildTraverse("ControlSettingsDirCastRight")
];
var controlSelfCast	 = [
	$.GetContextPanel().FindChildTraverse("ControlSettingsSelfCastLeft"),
	$.GetContextPanel().FindChildTraverse("ControlSettingsSelfCastMiddle"),
	$.GetContextPanel().FindChildTraverse("ControlSettingsSelfCastRight")
];
var controls = {
	"move" : controlMove,
	"dircast" : controlDirCast,
	"selfcast" : controlSelfCast
}

function setMouseControl(controlType, button) {
	var control = controls[controlType];
	var oldButton;
	for(var i = 0; i < 3; i++) {
		if(control[i].BHasClass("ActiveControlMouse")) {
			oldButton = i;
		}
		control[i].SetHasClass("ActiveControlMouse", button == i);
	}
	for(var key in controls) {
		if(key == controlType) {
			continue;
		}
		var otherControl = controls[key];
		if(otherControl[button].BHasClass("ActiveControlMouse")) {
			otherControl[button].SetHasClass("ActiveControlMouse", false);
			otherControl[oldButton].SetHasClass("ActiveControlMouse", true);
			break;
		}
	}
	var eventName = MOUSE_EVENTS[button];
	var actionName = ACTIONS[controlType];
	rebind(eventName + "_down", actionName + "_down");
	rebind(eventName + "_up", actionName + "_up");
}

var rebindingButton = null;
var rebindingActionName = null;
var elementKeyButtons = {
	"rm_pick_water"     : $.GetContextPanel().FindChildTraverse("ControlSettingsWaterKey"),
	"rm_pick_life"      : $.GetContextPanel().FindChildTraverse("ControlSettingsLifeKey"),
	"rm_pick_shield"    : $.GetContextPanel().FindChildTraverse("ControlSettingsShieldKey"),
	"rm_pick_cold"      : $.GetContextPanel().FindChildTraverse("ControlSettingsColdKey"),
	"rm_pick_lightning" : $.GetContextPanel().FindChildTraverse("ControlSettingsLightningKey"),
	"rm_pick_death"     : $.GetContextPanel().FindChildTraverse("ControlSettingsDeathKey"),
	"rm_pick_earth"     : $.GetContextPanel().FindChildTraverse("ControlSettingsEarthKey"),
	"rm_pick_fire"      : $.GetContextPanel().FindChildTraverse("ControlSettingsFireKey")
}
const ELEMENT_KEY_NAMES = {
	"+rm_key_q" : "Q",
	"+rm_key_w" : "W",
	"+rm_key_e" : "E",
	"+rm_key_r" : "R",
	"+rm_key_a" : "A",
	"+rm_key_s" : "S",
	"+rm_key_d" : "D",
	"+rm_key_f" : "F"
}

function enterRebindMode(actionName) {
	var button = elementKeyButtons[actionName];
	if(rebindingButton != button) {
		if(rebindingButton != null) {
			rebindingButton.SetHasClass("ActiveElementKeyRebind", false);
		}
		button.SetHasClass("ActiveElementKeyRebind", true);
		rebindingButton = button;
		rebindingActionName = actionName;
		startKeyCapture(onKeyCaptured);
	} else {
		leaveRebindMode();		
	}
}

function leaveRebindMode() {
	if(rebindingButton != null) {
		endKeyCapture();
		rebindingButton.SetHasClass("ActiveElementKeyRebind", false);
		rebindingButton = null;
		rebindingActionName = null;
	}
}

function onKeyCaptured(eventName) {
	if(!ELEMENT_KEY_NAMES.hasOwnProperty(eventName)) {
		return false;
	}
	var oldButton = elementKeyButtons[keybindTable[eventName]];
	var newKeyName = ELEMENT_KEY_NAMES[eventName];
	oldButton.GetChild(0).text = rebindingButton.GetChild(0).text;
	rebindingButton.GetChild(0).text = newKeyName;
	rebind(eventName, rebindingActionName);
	leaveRebindMode();
	return true;
}