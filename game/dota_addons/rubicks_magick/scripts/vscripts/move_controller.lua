require("addon_game_move.lua")

function RubickMove(args)
	local moveFrom = args.caster:GetAbsOrigin()
	local moveTo = playersMoveTo[args.caster:GetPlayerID()]
	local moveStep = (moveTo - moveFrom):Normalized() * 3.0
	args.caster:SetAbsOrigin(moveFrom + moveStep)
end