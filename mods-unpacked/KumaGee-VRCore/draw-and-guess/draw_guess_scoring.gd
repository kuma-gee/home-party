extends Node
class_name DrawGuessScoring

const MOBILE_SCORE_TABLE: Array[int] = [5, 4, 3, 2, 1]

var player_scores: Dictionary = {}

func init_player(uuid: String) -> void:
	if not player_scores.has(uuid):
		player_scores[uuid] = {
			total_points = 0,
			rounds_guessed_correctly = 0
		}

func award_mobile_points(uuid: String, guess_index: int) -> int:
	init_player(uuid)
	var points = MOBILE_SCORE_TABLE[guess_index] if guess_index < MOBILE_SCORE_TABLE.size() else 1
	var entry = player_scores[uuid]
	entry.total_points += points
	entry.rounds_guessed_correctly += 1
	return points

func get_scores() -> Array:
	var entries: Array = []
	for uuid in player_scores:
		var score = player_scores[uuid]
		entries.append({
			uuid = uuid,
			total_points = score.total_points,
			rounds_guessed_correctly = score.rounds_guessed_correctly
		})
	return entries
