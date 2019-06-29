$.Schedule(0, loop);

function loop() {
	var heroID = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
	if (heroID != -1) {
		GameUI.SetCameraPitchMin(65);
		GameUI.SetCameraPitchMax(65);

		var heroPos = Entities.GetAbsOrigin(heroID);
		var currentCameraPos = GameUI.GetCameraLookAtPosition();
		var cursorPos = GameUI.GetCursorPosition();

		var targetPos = calcCameraPos(heroPos, currentCameraPos, cursorPos, 0.6);
		GameUI.SetCameraTargetPosition(targetPos, 0.1);
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