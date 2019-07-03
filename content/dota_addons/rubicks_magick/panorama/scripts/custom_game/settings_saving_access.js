const READING_COMPLETED_FLAG = 1 << 30;
const READING_FAILED_FLAG = 1 << 29;
const VALUE_MASK = ~(READING_COMPLETED_FLAG | READING_FAILED_FLAG);

var settingsAccessorIndex = null;

setSettingsVisible(false);
var showSettingsTask = $.Schedule(3, function() { 
	showSettingsTask = null; 
	setSettingsVisible(true); 
});

GameEvents.Subscribe("rm_settings_loading", onSettingsLoadingStarted);
GameEvents.SendCustomGameEventToServer("rm_req_settings", { playerID: Players.GetLocalPlayer() });;

function onSettingsLoadingStarted(params) {
	settingsAccessorIndex = params.modifierIdx;
	$.Schedule(0.02, tryGetSettings);
}

function tryGetSettings() {
	var playerID = Players.GetLocalPlayer();
	var heroID = Players.GetPlayerHeroEntityIndex(playerID);
	var modifierID = Entities.GetBuff(heroID, settingsAccessorIndex);
	var value = Buffs.GetStackCount(heroID, modifierID);
	if ((value & READING_COMPLETED_FLAG) != 0) {
		if ((value & READING_FAILED_FLAG) == 0)
			onReadingCompletedSuccessfully(value & VALUE_MASK);
		else 
			onReadingFailed();
		return;
	}
	$.Schedule(0.02, tryGetSettings);
}

function onReadingCompletedSuccessfully(value) {
	cancelShowSettingsTask();
	decodeAndApplySettings(value);
}

function onReadingFailed() {
	cancelShowSettingsTask();
	setSettingsVisible(true);
}

function saveSettingsValue(value) {
	var keys = { 
		playerID: Players.GetLocalPlayer(),
		value: value
	};
	GameEvents.SendCustomGameEventToServer("rm_save_settings", keys);
}

function cancelShowSettingsTask() {
	if (showSettingsTask != null) {
		$.CancelScheduled(showSettingsTask);
		showSettingsTask = null;
	}
}

function decodeAndApplySettings(value) {
	var isSettingsHidden = decodeIsSettingsHidden(value & 1);
	var mouseBindings = decodeMouseBindings((value >> 1) & makeMask(3));
	var elementBindings = decodeElementBindings((value >> 4) & makeMask(17));
	var stopMovementBindings = decodeStopMovementBindings((value >> 21) & makeMask(2));

	setSettingsVisible(!isSettingsHidden);
	applyBindings(mouseBindings);
	applyBindings(elementBindings);
	applyBindings(stopMovementBindings);
}

function decodeIsSettingsHidden(value) {
	return value != 0;
}

function decodeMouseBindings(value) {
	var rawBindings = decodePermutations(value, mouseEvents, mouseActions);
	var result = {};
	for (var key in rawBindings) {
		result[key + "_down"] = rawBindings[key] + "_down";
		result[key + "_up"] = rawBindings[key] + "_up";
	}
	return result;
}

function decodeElementBindings(value) {
	return decodePermutations(value, elementEvents, elementActions);
}

function decodeStopMovementBindings(value) {
	var result = {};
	for (var i = 0; i < stopMoveEvents.length; i++) {
		result[stopMoveEvents[i]] = i == value ? stopMoveAction : null;
	}
	return result;
}

function decodePermutations(value, events, actions) {
	var result = {};
	actions = cloneArray(actions);
	var n = events.length - 1;
	for (var i = 0; i < n; i++) {
		var idxLength = bitsLength(n - i);
		var idx = value & makeMask(idxLength);
		value >>= idxLength;
		result[events[i]] = actions[idx];
		actions.splice(idx, 1);
	}
	result[events[n]] = actions[0]; // the last remaining element in 'actions'
	return result;
}

function makeMask(bits) {
	return (1 << bits) - 1;
}

function bitsLength(value) {
	return 1 + Math.floor(Math.log(value) / Math.log(2));
}

function cloneArray(array) {
	return array.slice(0);
}

function applyBindings(bindings) {
	for (var event in bindings) {
		rebind(event, bindings[event]);
	}
}

function saveSettings() {
	var isSettingsHiddenBits = encodeIsSettingsHidden();
	var mouseBindingsBits = encodeMouseBindings();
	var elementBindingsBits = encodeElementBindings();
	var stopMovementBindingsBits = encodeStopMovementBindings();
	var value = isSettingsHiddenBits | (mouseBindingsBits << 1) | (elementBindingsBits << 4) | (stopMovementBindingsBits << 21);
	saveSettingsValue(value);
}

function encodeIsSettingsHidden() {
	return isSettingsVisible() ? 0 : 1;
}

function encodeMouseBindings() {
	function addDownSuffix(array) {
		array = cloneArray(array);
		for (var i = 0; i < array.length; i++) {
			array[i] += "_down";
		}
		return array;
	}

	var events = addDownSuffix(mouseEvents);
	var actions = addDownSuffix(mouseActions);
	return encodePermutations(events, actions);
}

function encodeElementBindings() {
	return encodePermutations(elementEvents, elementActions);
}

function encodeStopMovementBindings() {
	for (var i = 0; i < stopMoveEvents.length; i++) {
		var event = stopMoveEvents[i];
		if (keybindTable[event] == stopMoveAction) {
			return i;
		}
	}
	return 0;
}

function encodePermutations(events, actions) {
	var result = 0;
	var shift = 0;
	actions = cloneArray(actions);
	var n = events.length - 1;
	for (var i = 0; i < n; i++) {
		var event = events[i];
		var boundAction = keybindTable[event]
		var idx = actions.indexOf(boundAction);
		var idxLength = bitsLength(n - i);
		result |= (idx << shift);
		shift += idxLength;
		actions.splice(idx, 1);		
	}
	return result;
}