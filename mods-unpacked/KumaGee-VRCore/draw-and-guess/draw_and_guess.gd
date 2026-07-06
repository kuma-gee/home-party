extends BaseGame

@export var vr_scene: XRToolsViewport2DIn3D

@export var timer_label: Label
@export var progress_label: Label
@export var reveal_label: Label

@onready var scoring: DrawGuessScoring = %Scoring
@onready var word_manager: DrawGuessWordManager = %WordManager
@onready var round_manager: DrawGuessRoundManager = %RoundManager
@onready var pet_spawner: DrawGuessPetSpawner = %PetSpawner
@onready var ai_manager: DrawGuessAIManager = %AIManager

var logger := KumaLog.new("DrawAndGuess")
var prepare_scene: DrawPrepareScene

const DRAW_PLAYER_UI_SCENE := preload("res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_player_ui.tscn")

func _ready() -> void:
	super()
	player_list.player_scene = DRAW_PLAYER_UI_SCENE
	PlayerManager.clients_changed.connect(_on_clients_changed)
	player_list.player_created.connect(_on_player_created)
	round_manager.timed_out.connect(_on_round_timed_out)
	round_manager.reveal_finished.connect(_start_next_round)
	round_manager.round_skipped.connect(_on_round_skipped)
	game_phase.connect(_on_game_phase)
	prepare_phase.connect(_on_prepare_phase)
	ai_manager.ai_guessed.connect(_on_player_guessed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.shift_pressed and event.keycode == KEY_1:
			_on_vr_ready_pressed()
	if not is_game_phase:
		if event.is_action_pressed("debug_ai_increase"):
			ai_manager.increase_ai_count()
		elif event.is_action_pressed("debug_ai_decrease"):
			ai_manager.decrease_ai_count()

func _on_prepare_phase():
	prepare_scene = vr_scene.get_scene_instance()
	prepare_scene.ready_clicked.connect(_on_vr_ready_pressed)
	prepare_scene.skipped.connect(func(): round_manager.skip_round())
	prepare_scene.round_timer = round_manager.round_timer
	ai_manager.on_prepare_phase_entered()
	_update_ui()
	_on_clients_changed()
	
func _on_clients_changed() -> void:
	LobbyServer.send_layout("guess")

	for child in player_list.get_children():
		if child is DrawPlayerUI:
			if is_game_phase:
				if round_manager.has_guessed(child.uuid):
					child.mark_guessed_correctly()
			elif word_manager.is_player_submitted(child.uuid):
				child.mark_word_submitted()

	_update_ui()
	
func _on_player_created(uuid: String) -> void:
	var player_ui = player_list.find_existing_node(uuid) as DrawPlayerUI
	if player_ui:
		player_ui.guessed.connect(_on_player_guessed.bind(player_ui))
		player_ui.reset_for_round()
		scoring.init_player(uuid)

func _on_player_word_submitted(word: String, player_ui: DrawPlayerUI) -> void:
	var pet := pet_spawner.get_pet(player_ui.uuid)
	if pet:
		pet.show_typed_word(word)
	var result = word_manager.submit_word(word, player_ui.uuid)
	match result:
		DrawGuessWordManager.SubmitResult.INVALID:
			if player_ui.game_client is GameClient:
				player_ui.game_client.send_text("word_ack;invalid")
			if pet:
				pet.on_incorrect_guess(word)
			logger.debug("Invalid word from %s: %s" % [player_ui.uuid, word.strip_edges()])
		DrawGuessWordManager.SubmitResult.DUPLICATE:
			if player_ui.game_client is GameClient:
				player_ui.game_client.send_text("word_ack;duplicate")
			if pet:
				pet.on_incorrect_guess(word)
			logger.debug("Duplicate word from %s: %s" % [player_ui.uuid, word.strip_edges()])
		DrawGuessWordManager.SubmitResult.ACCEPTED:
			player_ui.mark_word_submitted()
			if pet:
				pet.on_correct_guess(word)
			logger.info("Word accepted from %s: %s" % [player_ui.uuid, word.strip_edges()])
			_update_ui()

func _on_player_guessed(guess: String, player_ui: DrawPlayerUI) -> void:
	if not is_game_phase:
		_on_player_word_submitted(guess, player_ui)
		return

	if round_manager.phase == DrawGuessRoundManager.Phase.REVEALING:
		return
	
	if round_manager.has_guessed(player_ui.uuid):
		return
	
	if round_manager.player_guessed(player_ui.uuid, guess):
		logger.info("Correct guess from %s: %s" % [player_ui.uuid, guess])
		if player_ui.game_client is GameClient:
			player_ui.game_client.send_text("word_ack;correct")
		player_ui.mark_guessed_correctly()
		var pet := pet_spawner.get_pet(player_ui.uuid)
		if pet:
			pet.on_correct_guess(guess)
	else:
		logger.debug("Incorrect guess from %s: %s" % [player_ui.uuid, guess])
		if player_ui.game_client is GameClient:
			player_ui.game_client.send_text("word_ack;incorrect")
		player_ui.mark_guessed_incorrectly()
		var pet := pet_spawner.get_pet(player_ui.uuid)
		if pet:
			pet.on_incorrect_guess(guess)

func _update_ui() -> void:
	var active_players = PlayerManager.get_active_players().map(func(x): return player_list.find_existing_node(x.uuid))
	prepare_scene.update(active_players)

func _on_vr_ready_pressed() -> void:
	check_all_ready(true)

func _on_round_skipped(word: String) -> void:
	logger.info("VR player skipped word: %s" % word)
	_start_next_round()

func _on_game_phase() -> void:
	logger.info("Starting game with %d words in pool" % word_manager.size())
	_on_clients_changed()
	scoring.init_player(DrawGuessScoring.VR_PLAYER_ID)
	ai_manager.on_game_phase_entered()
	round_manager.start_game(word_manager.size())
	_start_next_round()

func _start_next_round() -> void:
	if word_manager.is_empty():
		_end_game()
		return
	
	var word = word_manager.pick_random_word()
	round_manager.start_round(word)
	ai_manager.start_game_round(word)
	
	logger.info("Round %d/%d: Word assigned" % [round_manager.current_round, round_manager.total_rounds])
	prepare_scene.start_new_game(round_manager.current_word, round_manager.current_round, round_manager.total_rounds)
	if progress_label:
		progress_label.text = round_manager.get_progress_text()
	
	reveal_label.hide()
	
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			child.reset_for_round()
	
	for pet in pet_spawner.get_children():
		if pet is DrawGuessPet:
			pet.reset_for_round()
	
	round_manager.start_round_timer()

func _on_round_timed_out(word: String) -> void:
	logger.info("Round %d timer expired, revealing word: %s" % [round_manager.current_round, word])
	
	if reveal_label:
		reveal_label.text = "The word was: %s" % word
		reveal_label.show()

func _end_game() -> void:
	round_manager.finish_game()
	ai_manager.stop_guessing()
	logger.info("Game ended - all words used")

	var entries:= scoring.get_scores()
	prepare_scene.show_leaderboard("Game Over!", entries)
	if desktop_gameover:
		desktop_gameover.show_leaderboard("Game Over!", entries)
