$.Schedule(1, function() {
	GameUI.SetCameraPitchMin(65);
	GameUI.SetCameraPitchMax(65);
});

var lastTime = Game.Time();
$.Schedule(0, loop);

function loop() {
	var currentTime = Game.Time();
	var deltaTime = currentTime - lastTime;
	lastTime = currentTime;

	var heroID = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
	if (heroID != -1) {
		var heroPos = Entities.GetAbsOrigin(heroID);
		var currentCameraPos = GameUI.GetCameraLookAtPosition();
		var cursorPos = GameUI.GetCursorPosition();

		var targetPos = calcCameraPos(heroPos, currentCameraPos, cursorPos, 0.65);
		GameUI.SetCameraTargetPosition(targetPos, 4.2 * deltaTime);
	}
	$.Schedule(0, loop);
}

function calcCameraPos(heroPos, currentCameraPos, cursorPos, lerpFactor) {
	var antiCursorPos = [Game.GetScreenWidth() - cursorPos[0], Game.GetScreenHeight() - cursorPos[1]];
	var antiPos = Game.ScreenXYToWorld(antiCursorPos[0], antiCursorPos[1]);
	var cameraPos = [];
	for (var i = 0; i < 3; i++)
		cameraPos[i] = heroPos[i] + lerpFactor * (currentCameraPos[i] - antiPos[i]);

	return cameraPos;
}