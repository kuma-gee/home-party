extends XRToolsSceneBase

signal game_ended()
signal round_started(word: String, round_number: int, total_rounds: int)
signal round_ended(word: String)
signal player_guessed_correctly(client: GameClient)

const ROUND_DURATION := 60.0
const REVEAL_DURATION := 5.0

@export var prepare_ui: Control
@export var game_ui: Control
@export var vr_prepare_scene: PackedScene
@export var pen_scene: PackedScene
@export var word_label: Label
@export var timer_label: Label
@export var progress_label: Label
@export var reveal_label: Label
@export var round_timer: Timer
@export var reveal_timer: Timer
@export var player_list: PlayerList

var logger := KumaLog.new("DrawAndGuess")
var word_pool: Array[String] = []
var submitted_players: Dictionary = {}
var prepare_scene: DrawPrepareScene
var is_drawing_phase := false
var vr_3d_pen: VR3DPen = null

var current_word: String = ""
var current_round: int = 0
var total_rounds: int = 0
var is_revealing := false
var guessed_players: Array[String] = []

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
	prepare_scene = xr_player.show_screen(vr_prepare_scene) as DrawPrepareScene
	prepare_scene.ready_button.pressed.connect(_on_vr_ready_pressed)
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
		player_ui.game_client.send_text("guess_ack;correct")
		player_ui.mark_guessed_correctly()
		player_guessed_correctly.emit(player_ui.game_client)
	else:
		logger.debug("Incorrect guess from %s: %s" % [player_ui.uuid, guess])
		player_ui.game_client.send_text("guess_ack;incorrect")
		player_ui.mark_guessed_incorrectly()

func _update_ui() -> void:
	if not is_drawing_phase:
		var active_client_count = 0
		for child in player_list.get_children():
			if child is DrawPlayerUI and child.has_submitted_word:
				active_client_count += 1
		
		var total_players = player_list.get_player_count()
		var text = "Players connected: %d\nWords submitted: %d / %d" % [
			total_players,
			active_client_count,
			total_players
		]
		prepare_scene.count_label.text = text

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

func _start_game() -> void:
	logger.info("Starting game with %d words in pool" % word_pool.size())
	is_drawing_phase = true
	prepare_ui.hide()
	game_ui.show()
	_on_clients_changed()
	_setup_drawing_pen()
	
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			child.set_phase("guess")
	
	total_rounds = word_pool.size()
	current_round = 0
	_start_next_round()

func _setup_drawing_pen():
	if not pen_scene:
		logger.warn("Pen scene not configured")
		return
	
	if vr_3d_pen:
		vr_3d_pen.queue_free()
	
	vr_3d_pen = pen_scene.instantiate()
	add_child(vr_3d_pen)
	
	var spawn_pos = xr_player.origin.global_transform.origin + Vector3(0.5, 1.2, -0.5)
	vr_3d_pen.global_position = spawn_pos

func _start_next_round() -> void:
	if word_pool.is_empty():
		_end_game()
		return
	
	current_round += 1
	var word_index = randi() % word_pool.size()
	current_word = word_pool[word_index]
	word_pool.remove_at(word_index)
	
	logger.info("Round %d/%d: Word assigned" % [current_round, total_rounds])
	
	if word_label:
		word_label.text = current_word
	if progress_label:
		progress_label.text = "Word %d of %d" % [current_round, total_rounds]
	
	reveal_label.hide()
	guessed_players.clear()
	
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			child.reset_for_round()
	
	round_started.emit(current_word, current_round, total_rounds)
	round_timer.start()

func _on_round_timer_expired() -> void:
	logger.info("Round %d timer expired, revealing word: %s" % [current_round, current_word])
	round_ended.emit(current_word)
	_reveal_word()

func _reveal_word() -> void:
	is_revealing = true
	if reveal_label:
		reveal_label.text = "The word was: %s" % current_word
		reveal_label.show()
	
	if vr_3d_pen:
		vr_3d_pen.set_drawing_enabled(false)
	
	reveal_timer.start(REVEAL_DURATION)

func _on_reveal_timer_expired() -> void:
	is_revealing = false
	if vr_3d_pen:
		vr_3d_pen.set_drawing_enabled(true)
	
	_start_next_round()

func _end_game() -> void:
	logger.info("Game ended - all words used")
	game_ended.emit()

func _update_timer_label(time_left: float) -> void:
	if timer_label:
		var minutes = int(time_left) / 60
		var seconds = int(time_left) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]

func _process(_delta: float) -> void:
	if round_timer and not round_timer.is_stopped():
		_update_timer_label(round_timer.time_left)
