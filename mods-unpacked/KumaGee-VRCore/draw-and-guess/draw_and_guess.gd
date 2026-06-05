extends XRToolsSceneBase

@export var prepare_ui: Control
@export var game_ui: Control
@export var vr_prepare_scene: PackedScene

var logger := KumaLog.new("DrawAndGuess")
var word_pool: Array[String] = []
var submitted_players: Dictionary = {}
var vr_player_ready := false
var prepare_scene: DrawPrepareScene
var is_started := false

func _ready() -> void:
	prepare_ui.show()
	game_ui.hide()
	PlayerManager.clients_changed.connect(_on_clients_changed)

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
	for client in PlayerManager.get_children():
		if client is GameClient:
			if not client.input_received.is_connected(_on_client_input_received.bind(client)):
				client.input_received.connect(_on_client_input_received.bind(client))
	LobbyServer.send_layout("word_submit" if not is_started else "guess")
	_update_ui()

func _on_client_input_received(input: String, value, client: GameClient) -> void:
	if input == "word":
		_handle_word_submission(value, client)

func _handle_word_submission(word: String, client: GameClient) -> void:
	var trimmed_word = word.strip_edges()
	
	if trimmed_word.length() < 3:
		client.send_text("word_ack;invalid")
		logger.debug("Word too short from %s: %s" % [client.uuid, trimmed_word])
		return
	
	if trimmed_word.length() > 20:
		client.send_text("word_ack;invalid")
		logger.debug("Word too long from %s: %s" % [client.uuid, trimmed_word])
		return
	
	var alphanumeric_regex = RegEx.new()
	alphanumeric_regex.compile("^[a-zA-Z0-9]+$")
	if not alphanumeric_regex.search(trimmed_word):
		client.send_text("word_ack;invalid")
		logger.debug("Word not alphanumeric from %s: %s" % [client.uuid, trimmed_word])
		return
	
	if trimmed_word.to_lower() in word_pool.map(func(w): return w.to_lower()):
		client.send_text("word_ack;duplicate")
		logger.debug("Duplicate word from %s: %s" % [client.uuid, trimmed_word])
		return
	
	word_pool.append(trimmed_word)
	submitted_players[client.uuid] = true
	client.send_text("word_ack;ok")
	logger.info("Word accepted from %s: %s" % [client.uuid, trimmed_word])
	
	_update_ui()
	_check_all_submitted()

func _update_ui() -> void:
	var active_client_count = 0
	for client in PlayerManager.get_children():
		if client is GameClient and client.active:
			active_client_count += 1
	
	var text = "Players connected: %d\nWords submitted: %d / %d" % [
		active_client_count,
		submitted_players.size(),
		active_client_count
	]
	prepare_scene.count_label.text = text

func _check_all_submitted() -> void:
	var all_submitted = true
	for client in PlayerManager.get_children():
		if client is GameClient and client.active:
			if not submitted_players.has(client.uuid):
				all_submitted = false
				break
	
	if all_submitted and vr_player_ready and PlayerManager.playing_clients.size() > 0:
		_start_game()

func _on_vr_ready_pressed() -> void:
	vr_player_ready = true
	logger.info("VR player ready")
	_check_all_submitted()

func _start_game() -> void:
	logger.info("Starting game with %d words in pool" % word_pool.size())
	is_started = true
	prepare_ui.hide()
	game_ui.show()
	_on_clients_changed()
