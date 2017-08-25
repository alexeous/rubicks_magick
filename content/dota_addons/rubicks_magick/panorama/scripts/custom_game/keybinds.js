/*const ELEMENT_SHIELD = 1;
const ELEMENT_EARTH = 2;
const ELEMENT_LIGHTNING = 3;
const ELEMENT_LIFE = 4;
const ELEMENT_DEATH = 5;
const ELEMENT_WATER = 6;
const ELEMENT_FIRE = 7;
const ELEMENT_COLD = 8;*/
/*
var keybindTable = {
	"+rm_key_q" : function() { Pick(ELEMENT_WATER); },
	"+rm_key_w" : function() { Pick(ELEMENT_LIFE); },
	"+rm_key_e" : function() { Pick(ELEMENT_SHIELD); },
	"+rm_key_r" : function() { Pick(ELEMENT_COLD); },
	"+rm_key_a" : function() { Pick(ELEMENT_LIGHTNING); },
	"+rm_key_s" : function() { Pick(ELEMENT_DEATH); },
	"+rm_key_d" : function() { Pick(ELEMENT_EARTH); },
	"+rm_key_f" : function() { Pick(ELEMENT_FIRE); },
	"+rm_key_ctrl" : function() { Stop(); }
};*/
/*
const ACTION_TABLE = {
	"pick_water" 	: function() { sendPickElementAction(ELEMENT_WATER); },
	"pick_life" 	: function() { sendPickElementAction(ELEMENT_LIFE); },
	"pick_shield" 	: function() { sendPickElementAction(ELEMENT_SHIELD); },
	"pick_cold" 	: function() { sendPickElementAction(ELEMENT_COLD); },
	"pick_lightning": function() { sendPickElementAction(ELEMENT_LIGHTNING); },
	"pick_death" 	: function() { sendPickElementAction(ELEMENT_DEATH); },
	"pick_earth" 	: function() { sendPickElementAction(ELEMENT_EARTH); },
	"pick_fire" 	: function() { sendPickElementAction(ELEMENT_FIRE); },
	"stop_move" 	: function() { sendSimpleAction("") },
	"move_to_down"		 : function() { moveToDown(); },
	"move_to_up"		 : function() { moveToUp(); },
	"directed_cast_down" : function() { directedCastDown(); },
	"directed_cast_up" 	 : function() { directedCastUp(); },
	"self_cast_down"	 : function() { selfCastDown(); },
	"self_cast_up"		 : function() { selfCastUp(); }
};*/

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
var oldDown = [ false, false, false ];

for (var key in keybindTable) {
	if(key[0] == '+') {
		addEvent(key);
	}
}
GameUI.SetMouseCallback( function(eventName, arg) {
	const CONSUME_EVENT = true;
	return CONSUME_EVENT;	// make our catcher consume mouse clicks
} );
mouseCycle();



function addEvent(eventName) {
	Game.AddCommand(eventName, function() { onKeyEvent(eventName); }, "", 0);
}

function onKeyEvent(eventName) {
	if(!keybindTable.hasOwnProperty(eventName)) {
		return;
	}
	var actionName = keybindTable[eventName];
	if(actionName == null) {
		return;
	}
	var playerID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer(actionName, { "playerID" : playerID });
}

function mouseCycle() {
	var cursorPos = GameUI.GetCursorPosition();
	var worldXYZ = Game.ScreenXYToWorld(cursorPos[0], cursorPos[1]);
	var keys = { 
		"playerID" : Players.GetLocalPlayer(),
		"worldX" : worldXYZ[0],
		"worldY" : worldXYZ[1],
		"worldZ" : worldXYZ[2]
	};
	GameEvents.SendCustomGameEventToServer("rm_mouse_cycle", keys);

	for(var i = 0; i < 3; i++) {
		var down = GameUI.IsMouseDown(i);
		if(down != oldDown[i]) {
			oldDown[i] = down;
			const mouseKey = ([ "left", "right", "middle" ])[i];
			var eventType = down ? "down" : "up";
			var eventName = "rm_mouse_" + mouseKey + "_" + eventType;
			onKeyEvent(eventName);
		}
	}
	
	$.Schedule(0.03, mouseCycle);
}