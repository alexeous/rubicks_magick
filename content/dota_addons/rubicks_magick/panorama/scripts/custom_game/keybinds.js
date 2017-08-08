const ELEMENT_SHIELD = 1;
const ELEMENT_EARTH = 2;
const ELEMENT_LIGHTNING = 3;
const ELEMENT_LIFE = 4;
const ELEMENT_DEATH = 5;
const ELEMENT_WATER = 6;
const ELEMENT_FIRE = 7;
const ELEMENT_COLD = 8;

Game.AddCommand("+rm_wtr",  function() { Pick(ELEMENT_WATER); }, "", 0);
Game.AddCommand("+rm_lif",  function() { Pick(ELEMENT_LIFE); }, "", 0);
Game.AddCommand("+rm_shld", function() { Pick(ELEMENT_SHIELD); }, "", 0);
Game.AddCommand("+rm_cld",  function() { Pick(ELEMENT_COLD); }, "", 0);
Game.AddCommand("+rm_ltg",  function() { Pick(ELEMENT_LIGHTNING); }, "", 0);
Game.AddCommand("+rm_dth",  function() { Pick(ELEMENT_DEATH); }, "", 0);
Game.AddCommand("+rm_ert",  function() { Pick(ELEMENT_EARTH); }, "", 0);
Game.AddCommand("+rm_fir",  function() { Pick(ELEMENT_FIRE); }, "", 0);

Game.AddCommand("+rm_stp", Stop, "", 0);

function Pick(element) {
	var playerID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer("pick_el", { "playerID" : playerID, "element" : element });
}

function Stop() {
	var playerID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer("stop_mv", { "playerID" : playerID });
}