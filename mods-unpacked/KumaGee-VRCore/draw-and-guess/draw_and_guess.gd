extends BaseGame

@export var vr_scene: XRToolsViewport2DIn3D
@export var instructions_vr_scene: XRToolsViewport2DIn3D
@export var camera_view: Node3D

@export var timer_label: Label
@export var progress_label: Label
@export var reveal_label: Label
@export var prepare_label: Label

@onready var scoring: DrawGuessScoring = %Scoring
@onready var word_manager: DrawGuessWordManager = %WordManager
@onready var round_manager: DrawGuessRoundManager = %RoundManager
@onready var pet_spawner: DrawGuessPetSpawner = %PetSpawner
@onready var ai_manager: DrawGuessAIManager = %AIManager

var logger := KumaLog.new("DrawAndGuess")
var prepare_scene: DrawPrepareScene
var freestyle_mode := false
var _game_settings_ai_prev := 0

const DRAW_PLAYER_UI_SCENE := preload("res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_player_ui.tscn")
const ROUND_START_CUE := preload("res://assets/sound/sfx/拍子木1.mp3")
const ROUND_START_FOLLOWUP_CUE := preload("res://assets/sound/sfx/拍子木2.mp3")
const CORRECT_GUESS_CUE := preload("res://assets/sound/sfx/成功音.mp3")
const WRONG_GUESS_CUE := preload("res://assets/sound/sfx/ビープ音4.mp3")

func _ready() -> void:
	super()
	player_list.player_scene = DRAW_PLAYER_UI_SCENE
	PlayerManager.clients_changed.connect(_on_clients_changed)
	player_list.player_created.connect(_on_player_created)
	round_manager.timed_out.connect(_on_round_timed_out)
	round_manager.reveal_finished.connect(_start_next_round)
	round_manager.round_skipped.connect(_on_round_skipped)
	round_manager.freestyle_round_ended.connect(_on_freestyle_round_ended)
	game_phase.connect(_on_game_phase)
	prepare_phase.connect(_on_prepare_phase)
	ai_manager.ai_guessed.connect(_on_player_guessed)

func _play_round_start_cue() -> void:
	AudioManager.play_sfx(ROUND_START_CUE)

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

func _debug_advance() -> void:
	if not is_game_phase:
		_on_vr_ready_pressed()
	elif round_manager.phase == DrawGuessRoundManager.Phase.DRAWING:
		round_manager.force_reveal()
	else:
		_end_game()

func _on_game_settings_ai_count_changed(new_count: int) -> void:
	if not ai_manager:
		return
	while _game_settings_ai_prev < new_count:
		ai_manager.increase_ai_count()
		_game_settings_ai_prev += 1
	while _game_settings_ai_prev > new_count:
		ai_manager.decrease_ai_count()
		_game_settings_ai_prev -= 1

func _on_prepare_phase():
	prepare_scene = vr_scene.get_scene_instance()
	prepare_scene.skipped.connect(func(): round_manager.skip_round())
	prepare_scene.continued.connect(func(): round_manager.continue_after_reveal())
	prepare_scene.ready_clicked.connect(_on_vr_ready_pressed)
	prepare_scene.freestyle_timer_started.connect(_on_freestyle_timer_started)
	prepare_scene.freestyle_correct.connect(func(): _on_freestyle_result(true))
	prepare_scene.freestyle_wrong.connect(func(): _on_freestyle_result(false))
	prepare_scene.freestyle_stopped.connect(_end_game)
	prepare_scene.round_timer = round_manager.round_timer

	instructions_vr_scene.visible = true
	camera_view.hide()

	ai_manager.on_prepare_phase_entered()
	
	# Sync AI count with global GameSettings (autoload that handles Ctrl+Alt+Up/Down)
	_game_settings_ai_prev = GameSettings.get_ai_count()
	if not GameSettings.ai_count_changed.is_connected(_on_game_settings_ai_count_changed):
		GameSettings.ai_count_changed.connect(_on_game_settings_ai_count_changed)
	
	_update_ui()
	_on_clients_changed()
	
func _on_clients_changed() -> void:
	LobbyServer.send_layout("guess")

	for child in player_list.get_children():
		if child is DrawPlayerUI:
			if child.game_client is GameClient and not child.game_client.data_channel_opened.is_connected(_sync_player_ui.bind(child)):
				child.game_client.data_channel_opened.connect(_sync_player_ui.bind(child))
			_sync_player_ui(child)

	_update_ui()

func _sync_player_ui(child: DrawPlayerUI) -> void:
	if freestyle_mode or _is_freestyle_available():
		_send_freestyle_phone_state(child)
	elif is_game_phase:
		if round_manager.has_guessed(child.uuid):
			child.mark_guessed_correctly()
	elif word_manager.is_player_submitted(child.uuid):
		child.mark_word_submitted(
			word_manager.get_player_submission_count(child.uuid),
			word_manager.max_words_per_player()
		)
	elif child.game_client is GameClient:
		child.game_client.send_text("word_ack;submit")

func _on_player_created(uuid: String) -> void:
	var player_ui = player_list.find_existing_node(uuid) as DrawPlayerUI
	if player_ui:
		player_ui.guessed.connect(_on_player_guessed.bind(player_ui))
		player_ui.reset_for_round()
		scoring.init_player(uuid)
		_on_clients_changed()

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
		DrawGuessWordManager.SubmitResult.LIMIT_REACHED:
			if player_ui.game_client is GameClient:
				player_ui.game_client.send_text("word_ack;limit;%d" % word_manager.max_words_per_player())
			if pet:
				pet.on_incorrect_guess(word)
			logger.debug("Word limit reached for %s" % player_ui.uuid)
		DrawGuessWordManager.SubmitResult.ACCEPTED:
			player_ui.mark_word_submitted(
				word_manager.get_player_submission_count(player_ui.uuid),
				word_manager.max_words_per_player()
			)
			if pet:
				pet.on_correct_guess(word)
			logger.info("Word accepted from %s: %s" % [player_ui.uuid, word.strip_edges()])
			_update_ui()

func _on_player_guessed(guess: String, player_ui: DrawPlayerUI) -> void:
	if freestyle_mode or _is_freestyle_available():
		if player_ui.game_client is GameClient:
			player_ui.game_client.send_text("word_ack;freestyle")
		var pet := pet_spawner.get_pet(player_ui.uuid)
		if pet:
			pet.show_typed_word(guess)
		return

	if not is_game_phase:
		_on_player_word_submitted(guess, player_ui)
		return

	if round_manager.phase == DrawGuessRoundManager.Phase.REVEALING:
		return
	
	if round_manager.has_guessed(player_ui.uuid):
		return
	
	if round_manager.player_guessed(player_ui.uuid, guess):
		logger.info("Correct guess from %s: %s" % [player_ui.uuid, guess])
		AudioManager.play_sfx(CORRECT_GUESS_CUE)
		if player_ui.game_client is GameClient:
			player_ui.game_client.send_text("word_ack;correct")
		player_ui.mark_guessed_correctly()
		var pet := pet_spawner.get_pet(player_ui.uuid)
		if pet:
			pet.on_correct_guess(guess)
	else:
		logger.debug("Incorrect guess from %s: %s" % [player_ui.uuid, guess])
		AudioManager.play_sfx(WRONG_GUESS_CUE)
		if player_ui.game_client is GameClient:
			player_ui.game_client.send_text("word_ack;incorrect")
		player_ui.mark_guessed_incorrectly()
		var pet := pet_spawner.get_pet(player_ui.uuid)
		if pet:
			pet.on_incorrect_guess(guess)

func _update_ui() -> void:
	var active_players = PlayerManager.get_active_players().map(func(x): return player_list.find_existing_node(x.uuid))
	if prepare_label:
		if _is_freestyle_available():
			prepare_label.text = "Freestyle mode!\n1 mobile player connected"
		else:
			var ready_players := 0
			for child in active_players:
				if child is DrawPlayerUI and word_manager.is_player_submitted(child.uuid):
					ready_players += 1
			prepare_label.text = "Submit at least one word!\n%d / %d players ready" % [ready_players, active_players.size()]
	if not prepare_scene:
		return
	prepare_scene.update_prepare_status(active_players, word_manager.size(), word_manager.max_words_per_player(), _is_freestyle_available())

func _on_vr_ready_pressed() -> void:
	if _is_freestyle_available():
		freestyle_mode = true
		_start_game()
		return

	if word_manager.is_empty():
		word_manager.fill_with_random_words()
		logger.debug("No submitted words - filled pool with fallback words")
		_update_ui()
		if PlayerManager.get_active_players().is_empty():
			_start_game()
			return
	check_all_ready(true)

func _on_round_skipped(word: String) -> void:
	logger.info("VR player skipped word: %s" % word)
	_start_next_round()

func _on_game_phase() -> void:
	# Stop listening to global AI count — fixed from here on
	if GameSettings.ai_count_changed.is_connected(_on_game_settings_ai_count_changed):
		GameSettings.ai_count_changed.disconnect(_on_game_settings_ai_count_changed)
	
	instructions_vr_scene.visible = false
	#camera_view.show()
	
	if freestyle_mode:
		logger.info("Starting freestyle mode")
		_on_clients_changed()
		ai_manager.stop_guessing()
		round_manager.start_freestyle_game()
		prepare_scene.show_freestyle_ready(0)
		if progress_label:
			progress_label.text = "Freestyle"
		if reveal_label:
			reveal_label.hide()
		return

	logger.info("Starting game with %d words in pool" % word_manager.size())
	_on_clients_changed()
	ai_manager.on_game_phase_entered()
	round_manager.start_game(word_manager.size())
	_start_next_round()

func _start_next_round() -> void:
	if word_manager.is_empty():
		_end_game()
		return
	
	var word = word_manager.pick_random_word()
	round_manager.start_round(word)
	_play_round_start_cue()
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
	AudioManager.play_sfx(ROUND_START_FOLLOWUP_CUE)
	
	if reveal_label:
		reveal_label.text = "The word was: %s" % word
		reveal_label.show()
	_send_phone_reveal(word)
	prepare_scene.show_reveal()

func _send_phone_reveal(word: String) -> void:
	for child in player_list.get_children():
		if child is DrawPlayerUI and child.game_client is GameClient:
			child.game_client.send_text("word_ack;reveal;%s" % word)

func _is_freestyle_available() -> bool:
	if is_game_phase:
		return false
	var active_count := PlayerManager.get_active_players().size()
	var mobile_count := 0
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			mobile_count += 1
	return active_count == 1 and mobile_count == 1

func _send_freestyle_phone_state(player_ui: DrawPlayerUI) -> void:
	if player_ui.game_client is GameClient:
		player_ui.game_client.send_text("word_ack;freestyle")

func _on_freestyle_timer_started() -> void:
	if not freestyle_mode:
		return
	round_manager.start_freestyle_round()
	_play_round_start_cue()
	prepare_scene.show_freestyle_drawing(round_manager.current_round)
	if progress_label:
		progress_label.text = round_manager.get_progress_text()
	if reveal_label:
		reveal_label.hide()
	for child in player_list.get_children():
		if child is DrawPlayerUI:
			child.reset_for_round()
			_send_freestyle_phone_state(child)
	for pet in pet_spawner.get_children():
		if pet is DrawGuessPet:
			pet.reset_for_round()

func _on_freestyle_result(guessed: bool) -> void:
	if not freestyle_mode:
		return
	AudioManager.play_sfx(CORRECT_GUESS_CUE if guessed else WRONG_GUESS_CUE)
	round_manager.complete_freestyle_round(guessed)

func _on_freestyle_round_ended(guessed: bool) -> void:
	if not freestyle_mode:
		return
	logger.info("Freestyle word %d ended: %s" % [round_manager.current_round, "guessed" if guessed else "missed"])
	prepare_scene.show_freestyle_ready(round_manager.current_round)
	if progress_label:
		progress_label.text = "Freestyle word %d done" % round_manager.current_round

func _end_game() -> void:
	# Stop listening to global AI count
	if GameSettings.ai_count_changed.is_connected(_on_game_settings_ai_count_changed):
		GameSettings.ai_count_changed.disconnect(_on_game_settings_ai_count_changed)
	
	round_manager.finish_game()
	ai_manager.stop_guessing()
	logger.info("Game ended - all words used")

	if freestyle_mode:
		if reveal_label:
			reveal_label.text = "Game Over!"
			reveal_label.show()
		finish_game("Game Over!")
		return

	var entries := scoring.get_scores()
	finish_game("Game Over!", func(lb): lb.set_entries(entries))
