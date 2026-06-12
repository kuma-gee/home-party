extends Node
class_name DrawGuessScoring

const MOBILE_SCORE_TABLE: Array[int] = [5, 4, 3, 2, 1]
const VR_PLAYER_ID := "vr_player"
const SPEED_BONUS_THRESHOLD := 15.0

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

func award_vr_points(correct_count: int, total_mobile: int, first_guess_elapsed: float) -> int:
	init_player(VR_PLAYER_ID)
	if total_mobile == 0:
		return 0
	var ratio = float(correct_count) / float(total_mobile)
	var points := 0
	if ratio >= 1.0:
		points = 5
	elif ratio >= 0.75:
		points = 4
	elif ratio >= 0.5:
		points = 3
	elif ratio >= 0.25:
		points = 2
	elif ratio > 0.0:
		points = 1
	if first_guess_elapsed >= 0.0 and first_guess_elapsed < SPEED_BONUS_THRESHOLD:
		points += 1
	player_scores[VR_PLAYER_ID].total_points += points
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
