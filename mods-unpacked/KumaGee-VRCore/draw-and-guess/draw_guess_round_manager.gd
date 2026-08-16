extends Node
class_name DrawGuessRoundManager

enum Phase { PRE_GAME, DRAWING, REVEALING, FINISHED, FREESTYLE_WAITING }

signal timed_out(word: String)
signal reveal_finished()
signal round_skipped(word: String)
signal freestyle_round_ended(guessed: bool)

var phase: Phase = Phase.PRE_GAME
var current_word: String = ""
## UUID of the player who submitted current_word ("" for fallback words).
var current_word_owner: String = ""
var current_round: int = 0
var total_rounds: int = 0
var guessed_players: Array[String] = []
var freestyle_mode := false

@onready var round_timer: Timer = %RoundTimer
@onready var scoring: DrawGuessScoring = %Scoring
@onready var player_list: PlayerList = %PlayerList

var logger := KumaLog.new("DrawRoundManager")

func _ready() -> void:
	round_timer.timeout.connect(_on_round_timeout)

func _count_eligible_guessers() -> int:
	var count := 0
	for child in player_list.get_children():
		if child is DrawPlayerUI and child.uuid != current_word_owner:
			count += 1
	return count

func get_elapsed_time() -> float:
	return round_timer.wait_time - round_timer.time_left

func start_game(word_count: int) -> void:
	freestyle_mode = false
	phase = Phase.DRAWING
	total_rounds = word_count
	current_round = 0

func start_freestyle_game() -> void:
	freestyle_mode = true
	phase = Phase.FREESTYLE_WAITING
	total_rounds = 0
	current_round = 0
	current_word = ""
	current_word_owner = ""
	guessed_players.clear()
	round_timer.stop()

func start_freestyle_round() -> void:
	if not freestyle_mode or phase != Phase.FREESTYLE_WAITING:
		return
	current_round += 1
	current_word = ""
	current_word_owner = ""
	phase = Phase.DRAWING
	guessed_players.clear()
	round_timer.start()

func complete_freestyle_round(guessed: bool) -> void:
	if not freestyle_mode or phase != Phase.DRAWING:
		return
	round_timer.stop()
	phase = Phase.FREESTYLE_WAITING
	freestyle_round_ended.emit(guessed)

func start_round(word: String, owner := "") -> void:
	current_round += 1
	current_word = word
	current_word_owner = owner
	phase = Phase.DRAWING
	guessed_players.clear()

func end_round() -> void:
	phase = Phase.REVEALING

func finish_reveal() -> void:
	phase = Phase.DRAWING

func finish_game() -> void:
	round_timer.stop()
	phase = Phase.FINISHED

func is_word_owner(uuid: String) -> bool:
	return uuid == current_word_owner

func player_guessed(uuid: String, word: String) -> bool:
	if is_word_owner(uuid):
		return false
	if current_word.to_lower() != word.strip_edges().to_lower():
		return false
	
	guessed_players.append(uuid)
	var guess_index = guessed_players.size() - 1
	
	var pts = scoring.award_mobile_points(uuid, guess_index)
	logger.info("Mobile player %s scored %d pts (index %d), total: %d" % [uuid, pts, guess_index, scoring.player_scores[uuid].total_points])
	_check_all_guessed()
	return true

func has_guessed(uuid: String) -> bool:
	return uuid in guessed_players

func _check_all_guessed() -> void:
	var total_eligible: int = _count_eligible_guessers()
	if total_eligible > 0 and guessed_players.size() >= total_eligible:
		_end_round_early()

func skip_round() -> void:
	if phase != Phase.DRAWING:
		return
	round_timer.stop()
	phase = Phase.REVEALING
	round_skipped.emit(current_word)

func _end_round_early() -> void:
	round_timer.stop()
	_on_round_timeout()

func force_reveal() -> void:
	if freestyle_mode or phase != Phase.DRAWING:
		return
	_end_round_early()

func start_round_timer() -> void:
	round_timer.start()

func continue_after_reveal() -> void:
	if phase != Phase.REVEALING:
		return
	finish_reveal()
	reveal_finished.emit()

func get_progress_text() -> String:
	if freestyle_mode:
		return "Freestyle word %d" % current_round
	return "Word %d of %d" % [current_round, total_rounds]

func _on_round_timeout() -> void:
	if freestyle_mode:
		phase = Phase.FREESTYLE_WAITING
		freestyle_round_ended.emit(false)
		return

	end_round()
	timed_out.emit(current_word)
