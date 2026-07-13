extends Node
class_name DrawGuessRoundManager

enum Phase { PRE_GAME, DRAWING, REVEALING, FINISHED, FREESTYLE_WAITING }

signal timed_out(word: String)
signal reveal_finished()
signal round_skipped(word: String)
signal freestyle_round_ended(guessed: bool)

var phase: Phase = Phase.PRE_GAME
var current_word: String = ""
var current_round: int = 0
var total_rounds: int = 0
var guessed_players: Array[String] = []
var first_guess_elapsed: float = -1.0
var freestyle_mode := false

@onready var round_timer: Timer = %RoundTimer
@onready var scoring: DrawGuessScoring = %Scoring
@onready var player_list: PlayerList = %PlayerList

var logger := KumaLog.new("DrawRoundManager")

func _ready() -> void:
	round_timer.timeout.connect(_on_round_timeout)

func _count_mobile_players() -> int:
	var count := 0
	for child in player_list.get_children():
		if child is DrawPlayerUI:
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
	guessed_players.clear()
	first_guess_elapsed = -1.0
	round_timer.stop()

func start_freestyle_round() -> void:
	if not freestyle_mode or phase != Phase.FREESTYLE_WAITING:
		return
	current_round += 1
	current_word = ""
	phase = Phase.DRAWING
	guessed_players.clear()
	first_guess_elapsed = -1.0
	round_timer.start()

func complete_freestyle_round(guessed: bool) -> void:
	if not freestyle_mode or phase != Phase.DRAWING:
		return
	round_timer.stop()
	phase = Phase.FREESTYLE_WAITING
	freestyle_round_ended.emit(guessed)

func start_round(word: String) -> void:
	current_round += 1
	current_word = word
	phase = Phase.DRAWING
	guessed_players.clear()
	first_guess_elapsed = -1.0

func end_round() -> void:
	phase = Phase.REVEALING

func finish_reveal() -> void:
	phase = Phase.DRAWING

func finish_game() -> void:
	round_timer.stop()
	phase = Phase.FINISHED

func player_guessed(uuid: String, word: String, elapsed: float = get_elapsed_time()) -> bool:
	if current_word.to_lower() != word.strip_edges().to_lower():
		return false
	
	guessed_players.append(uuid)
	if first_guess_elapsed < 0.0:
		first_guess_elapsed = elapsed
	var guess_index = guessed_players.size() - 1
	
	var pts = scoring.award_mobile_points(uuid, guess_index)
	logger.info("Mobile player %s scored %d pts (index %d), total: %d" % [uuid, pts, guess_index, scoring.player_scores[uuid].total_points])
	_check_all_guessed()
	return true

func has_guessed(uuid: String) -> bool:
	return uuid in guessed_players

func _check_all_guessed() -> void:
	var total_mobile: int = _count_mobile_players()
	if total_mobile > 0 and guessed_players.size() >= total_mobile:
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

	var total_mobile = _count_mobile_players()
	scoring.award_vr_points(guessed_players.size(), total_mobile, first_guess_elapsed)
	
	end_round()
	timed_out.emit(current_word)
