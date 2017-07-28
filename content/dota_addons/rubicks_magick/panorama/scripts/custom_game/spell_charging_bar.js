var playerID = Players.GetLocalPlayer();
var heroID = Players.GetPlayerHeroEntityIndex(playerID);
var panelStyle = $.GetContextPanel().style
var inside1 = $.GetContextPanel().FindChild("SpellChargingBarInside1");
var inside2 = $.GetContextPanel().FindChild("SpellChargingBarInside2");

var scaleX = 1920.0 / Game.GetScreenWidth();
var scaleY = 1080.0 / Game.GetScreenHeight();

function cycle() {
	var origin = Entities.GetAbsOrigin(heroID);
	var x = origin[0];
	var y = origin[1];
	var z = origin[2];

	z += 210.0;
	var screenX = Game.WorldToScreenX(x, y, z) * scaleX;
	var screenY = Game.WorldToScreenY(x, y, z) * scaleY;

	panelStyle.x = (screenX - 50) + "px";
	panelStyle.y = (screenY - 5) + "px";

	$.Schedule(0.01, cycle);
}

cycle();

inside1.style.transition = "width 1800.0ms linear 0.0ms;";
inside1.style.width = "100px";

inside2.style.transition = "width 500.0ms linear 1800.0ms;";
inside2.style.width = "100px";