GameUI.SetMouseCallback(function(eventName, arg) {
	const CONSUME_EVENT = true;
	const CONTINUE_PROCESSING_EVENT = false;
	if(eventName != "pressed" && eventName != "released") {
		return;
	}
	var mouseKey = ([ "left", "right", "middle" ])[arg];
	var eventSuffix = eventName == "pressed" ? "_down" : "_up";
	var eventName = "rm_mouse_" + mouseKey + eventSuffix;
	onKeyEvent(eventName);
	return CONSUME_EVENT;
});

mouseCycle();

function mouseCycle() {
	var cursorPos = GameUI.GetCursorPosition();
	var worldXYZ = Game.ScreenXYToWorld(cursorPos[0], cursorPos[1]);
	var keys = { 
		"playerID" : Players.GetLocalPlayer(),
		"x" : worldXYZ[0],
		"y" : worldXYZ[1],
		"z" : worldXYZ[2]
	};
	GameEvents.SendCustomGameEventToServer("rm_mouse_cycle", keys);
	$.Schedule(0.015, mouseCycle);
}