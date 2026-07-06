extends Node
class_name DrawGuessWordManager

enum SubmitResult { ACCEPTED, INVALID, DUPLICATE, LIMIT_REACHED }

const MAX_WORDS_PER_PLAYER := 3

var word_pool: Array[String] = []
var submitted_players: Array[String] = []
var submitted_counts: Dictionary = {}

func submit_word(word: String, player_uuid: String) -> SubmitResult:
	var trimmed = word.strip_edges()
	if trimmed.length() < 3 or trimmed.length() > 20:
		return SubmitResult.INVALID
	if get_player_submission_count(player_uuid) >= MAX_WORDS_PER_PLAYER:
		return SubmitResult.LIMIT_REACHED
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9]+$")
	if not regex.search(trimmed):
		return SubmitResult.INVALID
	if trimmed.to_lower() in word_pool.map(func(w): return w.to_lower()):
		return SubmitResult.DUPLICATE
	word_pool.append(trimmed)
	if not is_player_submitted(player_uuid):
		submitted_players.append(player_uuid)
	submitted_counts[player_uuid] = get_player_submission_count(player_uuid) + 1
	return SubmitResult.ACCEPTED

func is_player_submitted(uuid: String) -> bool:
	return get_player_submission_count(uuid) > 0

func get_player_submission_count(uuid: String) -> int:
	return int(submitted_counts.get(uuid, 0))

func max_words_per_player() -> int:
	return MAX_WORDS_PER_PLAYER

func submitted_player_count() -> int:
	return submitted_counts.size()

func pick_random_word() -> String:
	var idx = randi() % word_pool.size()
	var w = word_pool[idx]
	word_pool.remove_at(idx)
	return w

func size() -> int:
	return word_pool.size()

func is_empty() -> bool:
	return word_pool.is_empty()
