extends XRToolsSceneBase

signal game_ended()
signal round_started(word: String, round_number: int, total_rounds: int)
signal round_ended(word: String)
signal player_guessed_correctly(client: GameClient)
signal scoring_completed(scores: Dictionary)

const ROUND_DURATION := 60.0
const REVEAL_DURATION := 5.0
const SPEED_BONUS_THRESHOLD := 15.0  # seconds
const VR_PLAYER_ID := "vr_player"

# Scoring tables
const MOBILE_SCORE_TABLE: Array[int] = [5, 4, 3, 2, 1]

@export var prepare_ui: Control
@export var game_ui: Control

@export var vr_scene: XRToolsViewport2DIn3D

@export var timer_label: Label
@export var progress_label: Label
@export var reveal_label: Label
@export var round_timer: Timer
@export var reveal_timer: Timer

@export var player_list: PlayerList
@export var desktop_gameover: DesktopGameover

var logger := KumaLog.new("DrawAndGuess")
var word_pool: Array[String] = []
var submitted_players: Dictionary = {}
var is_drawing_phase := false
var vr_3d_pen: VR3DPen = null
var color_palette = null
var eraser_tool: EraserTool = null

var current_word: String = ""
var current_round: int = 0
var total_rounds: int = 0
var is_revealing := false
var guessed_players: Array[String] = []
var first_guess_elapsed: float = -1.0

# Per-player scoring: uuid -> {total_points: int, rounds_guessed_correctly: int}
var player_scores: Dictionary = {}
var prepare_scene: DrawPrepareScene

func _ready() -> void:
	prepare_ui.show()
	game_ui.hide()
	PlayerManager.clients_changed.connect(_on_clients_changed)
	round_timer.timeout.connect(_on_round_timer_expired)
	reveal_timer.timeout.connect(_on_reveal_timer_expired)
	player_list.player_created.connect(_on_player_created)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.shift_pressed and event.keycode == KEY_1:
			_on_vr_ready_pressed()

func _on_game_start():
	prepare_scene = vr_scene.get_scene_instance()
	prepare_scene.ready_clicked.connect(_on_vr_ready_pressed)
	prepare_scene.skipped.connect(_on_vr_skipped)
	prepare_scene.round_timer = round_timer
	_update_ui()
	_on_clients_changed()
	
func _on_clients_changed() -> void:
	LobbyServer.send_layout("guess" if is_drawing_phase else "word_submit")
	_update_ui()
	
func _on_player_created(uuid: String) -> void:
	var player_ui = player_list.find_existing_node(uuid) as DrawPlayerUI
	if player_ui:
		player_ui.word_submitted.connect(_on_player_word_submitted.bind(player_ui))
		player_ui.guessed.connect(_on_player_guessed.bind(player_ui))
		player_ui.reset_for_round()
		_init_player_score(uuid)

func _on_player_word_submitted(word: String, player_ui: DrawPlayerUI) -> void:
	var trimmed_word = word.strip_edges()
	
	if trimmed_word.length() < 3:
		player_ui.game_client.send_text("word_ack;invalid")
		logger.debug("Word too short from %s: %s" % [player_ui.uuid, trimmed_word])
		return
	
	if trimmed_word.length() > 20:
		player_ui.game_client.send_text("word_ack;invalid")
		logger.debug("Word too long from %s: %s" % [player_ui.uuid, trimmed_word])
		return
	
	var alphanumeric_regex = RegEx.new()
	alphanumeric_regex.compile("^[a-zA-Z0-9]+$")
	if not alphanumeric_regex.search(trimmed_word):
		player_ui.game_client.send_text("word_ack;invalid")
		logger.debug("Word not alphanumeric from %s: %s" % [player_ui.uuid, trimmed_word])
		return
	
	if trimmed_word.to_lower() in word_pool.map(func(w): return w.to_lower()):
		player_ui.game_client.send_text("word_ack;duplicate")
		logger.debug("Duplicate word from %s: %s" % [player_ui.uuid, trimmed_word])
		return
	
	word_pool.append(trimmed_word)
	submitted_players[player_ui.uuid] = true
	player_ui.game_client.send_text("word_ack;ok")
	player_ui.mark_word_submitted()
	logger.info("Word accepted from %s: %s" % [player_ui.uuid, trimmed_word])
	
	_update_ui()
	_check_all_submitted()

func _on_player_guessed(guess: String, player_ui: DrawPlayerUI) -> void:
	if not is_drawing_phase or is_revealing:
		return
	
	if player_ui.uuid in guessed_players:
		return
	
	var trimmed_guess = guess.strip_edges().to_lower()
	if trimmed_guess == current_word.to_lower():
		logger.info("Correct guess from %s: %s" % [player_ui.uuid, guess])
		guessed_players.append(player_ui.uuid)
		player_ui.game_client.send_text("word_ack;correct")
		player_ui.mark_guessed_correctly()
		player_guessed_correctly.emit(player_ui.game_client)
		
		# Award mobile player points based on guess order
		_award_mobile_points(player_ui.uuid)
		
		# Track first guess elapsed time for VR speed bonus
		if first_guess_elapsed < 0.0:
			first_guess_elapsed = round_timer.wait_time - round_timer.time_left
	else:
		logger.debug("Incorrect guess from %s: %s" % [player_ui.uuid, guess])
		player_ui.game_client.send_text("word_ack;incorrect")
		player_ui.mark_guessed_incorrectly()

func _init_player_score(uuid: String) -> void:
	if not player_scores.has(uuid):
		player_scores[uuid] = {
			total_points = 0,
			rounds_guessed_correctly = 0
		}

func _award_mobile_points(uuid: String) -> void:
	_init_player_score(uuid)
	var guess_index = guessed_players.find(uuid)
	var points = MOBILE_SCORE_TABLE[guess_index] if guess_index < MOBILE_SCORE_TABLE.size() else 1
	var entry = player_scores[uuid]
	entry.total_points += points
	entry.rounds_guessed_correctly += 1
	logger.info("Mobile player %s scored %d pts (index %d), total: %d" % [uuid, points, guess_index, entry.total_points])

func _calculate_vr_score() -> void:
	_init_player_score(VR_PLAYER_ID)
	
	var total_mobile = 0
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			total_mobile += 1
	
	if total_mobile == 0:
		return
	
	var correct_count = guessed_players.size()
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
	# else points stays 0
	
	# Speed bonus: +1 if first guess arrived under 15 seconds
	var speed_bonus := 0
	if first_guess_elapsed >= 0.0 and first_guess_elapsed < SPEED_BONUS_THRESHOLD:
		speed_bonus = 1
		logger.info("VR speed bonus earned (first guess at %.1fs)" % first_guess_elapsed)
	
	points += speed_bonus
	
	var entry = player_scores[VR_PLAYER_ID]
	entry.total_points += points
	logger.info("VR player scored %d pts (guess ratio %.0f%%), total: %d" % [points, ratio * 100, entry.total_points])

func get_player_scores() -> Dictionary:
	return player_scores.duplicate()

func _update_ui() -> void:
	prepare_scene.update(player_list.get_children())

func _check_all_submitted(vr_ready = false) -> void:
	var all_submitted = true
	for child in player_list.get_children():
		if child is DrawPlayerUI and not child.has_submitted_word:
			all_submitted = false
			break
	
	if all_submitted and vr_ready and PlayerManager.playing_clients.size() > 0:
		_start_game()

func _on_vr_ready_pressed() -> void:
	logger.info("VR player ready")
	_check_all_submitted(true)

func _on_vr_skipped() -> void:
	if not is_drawing_phase or is_revealing:
		return
	
	round_timer.stop()
	logger.info("VR player skipped word: %s" % current_word)
	round_ended.emit(current_word)
	scoring_completed.emit(player_scores.duplicate())
	_start_next_round()

func _start_game() -> void:
	logger.info("Starting game with %d words in pool" % word_pool.size())
	is_drawing_phase = true
	prepare_ui.hide()
	game_ui.show()
	_on_clients_changed()
	_init_player_score(VR_PLAYER_ID)
	
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			child.set_phase("guess")
	
	total_rounds = word_pool.size()
	current_round = 0
	_start_next_round()

func _start_next_round() -> void:
	if word_pool.is_empty():
		_end_game()
		return
	
	current_round += 1
	var word_index = randi() % word_pool.size()
	current_word = word_pool[word_index]
	word_pool.remove_at(word_index)
	
	logger.info("Round %d/%d: Word assigned" % [current_round, total_rounds])
	prepare_scene.start_new_game(current_word, current_round, total_rounds)
	if progress_label:
		progress_label.text = "Word %d of %d" % [current_round, total_rounds]
	
	reveal_label.hide()
	guessed_players.clear()
	first_guess_elapsed = -1.0
	
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			child.reset_for_round()
	
	round_started.emit(current_word, current_round, total_rounds)
	round_timer.start()

func _on_round_timer_expired() -> void:
	logger.info("Round %d timer expired, revealing word: %s" % [current_round, current_word])
	round_ended.emit(current_word)
	_calculate_vr_score()
	scoring_completed.emit(player_scores.duplicate())
	_reveal_word()

func _reveal_word() -> void:
	is_revealing = true
	if reveal_label:
		reveal_label.text = "The word was: %s" % current_word
		reveal_label.show()
	
	reveal_timer.start(REVEAL_DURATION)

func _on_reveal_timer_expired() -> void:
	is_revealing = false
	_start_next_round()

func _end_game() -> void:
	logger.info("Game ended - all words used")
	game_ended.emit()

	var entries: Array = []
	for uuid in player_scores:
		var score = player_scores[uuid]
		entries.append({
			uuid = uuid,
			total_points = score.total_points,
			rounds_guessed_correctly = score.rounds_guessed_correctly
		})

	prepare_ui.show_leaderboard("Game Over!", entries)
	if desktop_gameover:
		desktop_gameover.show_leaderboard("Game Over!", entries)
