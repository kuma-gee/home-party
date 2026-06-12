extends Node
class_name DrawGuessWordManager

enum SubmitResult { ACCEPTED, INVALID, DUPLICATE }

var word_pool: Array[String] = []
var submitted_players: Array[String] = []

func submit_word(word: String, player_uuid: String) -> SubmitResult:
	var trimmed = word.strip_edges()
	if trimmed.length() < 3 or trimmed.length() > 20:
		return SubmitResult.INVALID
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9]+$")
	if not regex.search(trimmed):
		return SubmitResult.INVALID
	if trimmed.to_lower() in word_pool.map(func(w): return w.to_lower()):
		return SubmitResult.DUPLICATE
	word_pool.append(trimmed)
	submitted_players.append(player_uuid)
	return SubmitResult.ACCEPTED

func is_player_submitted(uuid: String) -> bool:
	return uuid in submitted_players

func pick_random_word() -> String:
	var idx = randi() % word_pool.size()
	var w = word_pool[idx]
	word_pool.remove_at(idx)
	return w

func size() -> int:
	return word_pool.size()

func is_empty() -> bool:
	return word_pool.is_empty()
