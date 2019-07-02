const READING_COMPLETED_FLAG = 1 << 30;
const READING_FAILED_FLAG = 1 << 29;


GameEvents.Subscribe("rm_settings_loading", onSettingsHolderCreated);
GameEvents.SendCustomGameEventToServer("rm_send_settings", { "playerID" : Players.GetLocalPlayer() });

var settingsHolderIndex = null;

function onSettingsHolderCreated(params) {
	settingsHolderIndex = params.holder;
	$.Schedule(0.02, tryGetSettings);
}


function tryGetSettings() {
	var value = Buffs.GetStackCount(settingsHolderIndex, 2);
	if ((value & READING_COMPLETED_FLAG) != 0) {		
		onReadingCompleted(value);
		return;
	}
	$.Schedule(0.02, tryGetSettings);
}

function onReadingCompleted(value) {

}