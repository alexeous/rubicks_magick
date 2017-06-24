var oldCursorPos = [];
var oldDown = [ false, false, false ];

function cycle() {
	var cursorPos = GameUI.GetCursorPosition();
	if(cursorPos[0] != oldCursorPos[0] || cursorPos[1] != oldCursorPos[1]) {
		oldCursorPos = cursorPos;
		onMouseMove(cursorPos);
	}
	for(var i = 0; i < 3; i++) {
		var down = GameUI.IsMouseDown(i);
		if(down != oldDown[i]) {
			oldDown[i] = down;
			onMouseDownOrUp(i, down, cursorPos);
		}
	}

	$.Schedule(0.03, cycle);
}
cycle();
// make our catcher consume mouse clicks
GameUI.SetMouseCallback( function(eventName, arg) {
	const CONSUME_EVENT = true;
	return CONSUME_EVENT;
} );




function onMouseMove(cursorPos) {
	var worldXYZ = Game.ScreenXYToWorld(cursorPos[0], cursorPos[1]);
	var keys = { 
		"playerID" : Game.GetLocalPlayerID(),
		"worldX" : worldXYZ[0],
		"worldY" : worldXYZ[1],
		"worldZ" : worldXYZ[2]
	};
	GameEvents.SendCustomGameEventToServer("me_mm", keys);
}

const mouseLetters = [ 'l', 'r', 'm' ];
function onMouseDownOrUp(num, isDown, cursorPos) {
	const eventPrefix = "me_";
	var eventMouseLetter = mouseLetters[num];
	var eventType = isDown ? 'd' : 'u';
	var eventName =  eventPrefix + eventMouseLetter + eventType;
	var worldXYZ = Game.ScreenXYToWorld(cursorPos[0], cursorPos[1]);
	var keys = { 
		"playerID" : Game.GetLocalPlayerID(),
		"worldX" : worldXYZ[0],
		"worldY" : worldXYZ[1],
		"worldZ" : worldXYZ[2]
	};
	GameEvents.SendCustomGameEventToServer(eventName, keys);
}