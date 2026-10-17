class_name PirateArcRules
extends RefCounted

const DIRECTIONS: Array[String] = ["up", "right", "down", "left"]


static func resolve_gamble_round(progress: Dictionary, direction: String, die: int) -> String:
	if direction not in DIRECTIONS or die not in range(1, 7):
		return "invalid"
	var round_index: int = int(progress.gamble_round)
	if round_index == 0:
		progress.gamble_round = 1
		progress.gamble_result = "lost_first"
		return "lost_first"
	if round_index == 1:
		if direction != "up" or die < 3:
			return "retry"
		progress.gamble_round = 2
		progress.gamble_result = "won_second"
		return "won_second"
	if round_index == 2:
		if direction != "left" or die > 4:
			return "retry"
		progress.gamble_round = 3
		progress.gamble_result = "cleared"
		progress.qiu_arrested = true
		return "qiu_arrested"
	return "complete"


static func control_chance(successful_chain: int, immunity_turns: int) -> float:
	if immunity_turns > 0 or successful_chain >= 2:
		return 0.0
	return 0.40 if successful_chain == 0 else 0.20


static func resolves_control(roll: float, successful_chain: int, immunity_turns: int) -> bool:
	return clampf(roll, 0.0, 1.0) < control_chance(successful_chain, immunity_turns)
