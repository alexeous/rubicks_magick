Game.AddCommand("+rm_wtr",  function() { Pick(1); }, "", 0);
Game.AddCommand("+rm_lif",  function() { Pick(2); }, "", 0);
Game.AddCommand("+rm_shld", function() { Pick(3); }, "", 0);
Game.AddCommand("+rm_cld",  function() { Pick(4); }, "", 0);
Game.AddCommand("+rm_ltg",  function() { Pick(5); }, "", 0);
Game.AddCommand("+rm_dth",  function() { Pick(6); }, "", 0);
Game.AddCommand("+rm_ert",  function() { Pick(7); }, "", 0);
Game.AddCommand("+rm_fir",  function() { Pick(8); }, "", 0);

Game.AddCommand("+rm_stp", Stop, "", 0);

function Pick(element) {
	var playerID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer("pick_el", { "playerID" : playerID, "element" : element });
}

function Stop() {
	var playerID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer("stop_mv", { "playerID" : playerID });
}