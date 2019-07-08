var enabled = false

var playerID = Players.GetLocalPlayer();
var panelStyle = $.GetContextPanel().style
var inside1 = $.GetContextPanel().FindChild("SpellChargingBarInside1");
var inside2 = $.GetContextPanel().FindChild("SpellChargingBarInside2");

var scaleX = 1920.0 / Game.GetScreenWidth();
var scaleY = 1080.0 / Game.GetScreenHeight();

var inside2scheduled = null;

GameEvents.Subscribe("rm_cb_e", enable);
GameEvents.Subscribe("rm_cb_d", disable);
disable(null);

function enable(params) {
	enabled = true;
	barHeroFollowCycle();
	
	var phase1 = params.phase1;
	var phase2 = params.phase2;
	inside1.style.transition = "width " + phase1 +  "s linear 0.0ms;";
	inside1.style.width = "100px";

	inside2scheduled = $.Schedule(phase1, function() {
		inside2scheduled = null;
		inside2.style.transition = "width " + phase2 + "s linear 0.0ms;";
		inside2.style.width = "100px";
	});
}

function disable(params) {
	panelStyle.x = "-10000px";
	panelStyle.y = "-10000px";
	enabled = false;

	inside1.style.transition = null;
	inside1.style.width = "0px";

	inside2.style.transition = null;
	inside2.style.width = "0px";
	if(inside2scheduled != null) {
		$.CancelScheduled(inside2scheduled);
		inside2scheduled = null;
	}
}

function barHeroFollowCycle() {
	if(!enabled) 
		return;

	var origin = Entities.GetAbsOrigin(Players.GetPlayerHeroEntityIndex(playerID));
	var x = origin[0];
	var y = origin[1];
	var z = origin[2];

	z += 200.0;
	var screenX = Game.WorldToScreenX(x, y, z) * scaleX;
	var screenY = Game.WorldToScreenY(x, y, z) * scaleY;

	panelStyle.x = (screenX - 50) + "px";
	panelStyle.y = (screenY - 13) + "px";

	$.Schedule(0.01, barHeroFollowCycle);
}
