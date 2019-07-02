const elementKeyNames = {
	"+rm_key_q" : "Q",
	"+rm_key_w" : "W",
	"+rm_key_e" : "E",
	"+rm_key_r" : "R",
	"+rm_key_a" : "A",
	"+rm_key_s" : "S",
	"+rm_key_d" : "D",
	"+rm_key_f" : "F"
};


var hideButton = findUI("ControlSettingsHideButton");
var showButton = findUI("ControlSettingsShowButton");
var controlSettingsPanel = findUI("ControlSettings");
var rebindHint = findUI("ControlElementRebindHint");


var buttonsMove = makeTable(
	mouseEvents[0], findUI("ControlSettingsMoveLeft"),
	mouseEvents[1], findUI("ControlSettingsMoveMiddle"),
	mouseEvents[2], findUI("ControlSettingsMoveRight")
);
var buttonsDirCast = makeTable(
	mouseEvents[0], findUI("ControlSettingsDirCastLeft"),
	mouseEvents[1], findUI("ControlSettingsDirCastMiddle"),
	mouseEvents[2], findUI("ControlSettingsDirCastRight")
);
var buttonsSelfCast = makeTable(
	mouseEvents[0], findUI("ControlSettingsSelfCastLeft"),
	mouseEvents[1], findUI("ControlSettingsSelfCastMiddle"),
	mouseEvents[2], findUI("ControlSettingsSelfCastRight")
);

var mouseButtonGroups = makeTable(
	mouseActions[0], buttonsMove,
	mouseActions[1], buttonsDirCast,
	mouseActions[2], buttonsSelfCast
);

var elementButtons = makeTable(
	elementActions[0], findUI("ControlSettingsWaterKey"),
	elementActions[1], findUI("ControlSettingsLifeKey"),
	elementActions[2], findUI("ControlSettingsShieldKey"),
	elementActions[3], findUI("ControlSettingsColdKey"),
	elementActions[4], findUI("ControlSettingsLightningKey"),
	elementActions[5], findUI("ControlSettingsDeathKey"),
	elementActions[6], findUI("ControlSettingsEarthKey"),
	elementActions[7], findUI("ControlSettingsFireKey")
);

var buttonsStopMove = makeTable(
	stopMoveEvents[0], findUI("ControlSettingsStopMoveCtrl"),
	stopMoveEvents[1], findUI("ControlSettingsStopMoveSpace"),
	stopMoveEvents[2], findUI("ControlSettingsStopMoveTab"),
	stopMoveEvents[3], findUI("ControlSettingsStopMoveShift")
);

const saveScheduleTime = 6;

var rebindingButton = null;
var saveScheduled = null;


setOnRebindCallback(invalidateControls);
invalidateControls();

function findUI(name) {
	return $.GetContextPanel().FindChildTraverse(name);
}

function makeTable() {
	var table = {};
	for (var i = 0; i < arguments.length; i += 2) {
		var key = arguments[i];
		var value = arguments[i + 1];
		table[key] = value;
	}
	return table;
}

function invalidateControls() {
	invalidateMouseControls();
	invalidateElementControls();
	invalidateStopMoveControls();
}

function invalidateMouseControls() {
	for (var action of mouseActions) {
		var buttons = mouseButtonGroups[action];
		for (var event of mouseEvents) {
			var button = buttons[event];
			var isBound = keybindTable[event + "_down"] == action + "_down";
			button.SetHasClass("ActiveControl", isBound); 
			button.GetChild(0).SetHasClass("ControlSettingsSelectedButtonText", isBound);
		}
	}
}

function invalidateElementControls() {
	for (var action of elementActions) {
		var button = elementButtons[action];
		var event = getKey(keybindTable, action);
		var keyName = elementKeyNames[event];
		button.GetChild(0).text = keyName;
	}
}

function invalidateStopMoveControls() {
	for (var event of stopMoveEvents) {
		var button = buttonsStopMove[event];
		var isBound = stopMoveAction == keybindTable[event];
		button.SetHasClass("ActiveControl", isBound);
		button.GetChild(0).SetHasClass("ControlSettingsSelectedButtonText", isBound);
	}
}

function setSettingsVisible(visible) {
	hideButton.SetHasClass("invisible", !visible);
	showButton.SetHasClass("invisible", visible);
	controlSettingsPanel.SetHasClass("invisible", !visible);
	leaveKeyRebind();
}

function setSettingsVisibleAndSave(visible) {
	setSettingsVisible(visible);
	scheduleSave();
}

function isSettingsVisible() {
	return !controlSettingsPanel.BHasClass("invisible");
}

function rebindMouse(actionIdx, eventIdx) {
	var action = mouseActions[actionIdx];
	var event = mouseEvents[eventIdx];
	rebind(event + "_down", action + "_down");
	rebind(event + "_up", action + "_up");
	scheduleSave();
}

function toggleKeyRebind(actionIdx) {
	var action = elementActions[actionIdx];
	var button = elementButtons[action];
	if (rebindingButton == button) {
		leaveKeyRebind();
	}
	else {
		leaveKeyRebind();
		enterKeyRebind(action);
	}
}

function enterKeyRebind(action) {
	var button = elementButtons[action];
	rebindingButton = button;
	startKeyCapture(function(event) {
		if (!(event in elementKeyNames)) {
			return false;
		}
		rebind(event, action);
		scheduleSave();
		leaveKeyRebind();
		return true;
	});
	button.SetHasClass("ActiveElementKeyRebind", true);
	rebindHint.SetHasClass("invisible", false);
}

function leaveKeyRebind() {
	endKeyCapture();
	if(rebindingButton != null) {
		rebindingButton.SetHasClass("ActiveElementKeyRebind", false);
		rebindingButton = null;
	}
	rebindHint.SetHasClass("invisible", true);
}

function setStopMoveControl(buttonIdx) {
	var event = stopMoveEvents[buttonIdx];
	rebind(event, stopMoveAction);
	scheduleSave();
}

function scheduleSave() {
	if (saveScheduled != null) {
		$.CancelScheduled(saveScheduled);
		saveScheduled = null;
	}
	saveScheduled = $.Schedule(saveScheduleTime, function() {
		saveScheduled = null;
		saveSettings();
	});
}