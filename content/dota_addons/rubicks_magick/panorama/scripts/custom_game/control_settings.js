var hideButton = $.GetContextPanel().FindChildTraverse("ControlSettingsHideButton")
var showButton = $.GetContextPanel().FindChildTraverse("ControlSettingsShowButton")
var controlSettingsPanel = $.GetContextPanel().FindChildTraverse("ControlSettings")

function onHideShowClick() {
	hideButton.ToggleClass("invisible");
	showButton.ToggleClass("invisible");
	controlSettingsPanel.ToggleClass("invisible");
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