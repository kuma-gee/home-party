extends Node
class_name DrawGuessRoundManager

enum Phase { PRE_GAME, DRAWING, REVEALING, FINISHED }

signal timed_out(word: String)
signal reveal_finished()
signal round_skipped(word: String)

var phase: Phase = Phase.PRE_GAME
var current_word: String = ""
var current_round: int = 0
var total_rounds: int = 0
var guessed_players: Array[String] = []
var first_guess_elapsed: float = -1.0

@onready var round_timer: Timer = %RoundTimer
@onready var reveal_timer: Timer = %RevealTimer
@onready var scoring: DrawGuessScoring = %Scoring
@onready var player_list: PlayerList = %PlayerList

var logger := KumaLog.new("DrawRoundManager")

func _ready() -> void:
	round_timer.timeout.connect(_on_round_timeout)
	reveal_timer.timeout.connect(_on_reveal_timeout)

func _count_mobile_players() -> int:
	var count := 0
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			count += 1
	return count

func get_elapsed_time():
	return round_timer.wait_time - round_timer.time_left

func start_game(word_count: int) -> void:
	phase = Phase.DRAWING
	total_rounds = word_count
	current_round = 0

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

func start_round_timer() -> void:
	round_timer.start()

func start_reveal_timer(duration: float) -> void:
	reveal_timer.start(duration)

func get_progress_text() -> String:
	return "Word %d of %d" % [current_round, total_rounds]

func _on_round_timeout() -> void:
	var total_mobile = _count_mobile_players()
	scoring.award_vr_points(guessed_players.size(), total_mobile, first_guess_elapsed)
	
	end_round()
	timed_out.emit(current_word)
	reveal_timer.start()

func _on_reveal_timeout() -> void:
	finish_reveal()
	reveal_finished.emit()
