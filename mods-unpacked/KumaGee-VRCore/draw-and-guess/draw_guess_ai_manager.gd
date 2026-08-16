class_name DrawGuessAIManager
extends Node

## Manages AI-controlled players for the Draw & Guess game.
## AI players simulate real phone players: they have a plushie and a DrawAIPlayer UI.
## During the prepare phase they auto-submit a random word.
## During the game phase they periodically guess; after 5 s there is a chance to guess correctly.

const DRAW_AI_PLAYER_SCENE := preload("res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_ai_player.tscn")

const WORD_LIST := [
	"apple", "boat", "cat", "dog", "house", "tree", "car", "sun", "moon",
	"star", "bird", "fish", "hat", "book", "cup", "key", "lamp", "door",
	"cloud", "rain", "cake", "ball", "frog", "duck", "cow", "pig", "ant",
	"bee", "bag", "bus", "fox", "gem", "ice", "jam", "jar", "jet",
	"kit", "log", "map", "mug", "net", "owl", "pan", "pin", "pot",
	"rat", "rod", "saw", "tag", "tin", "van", "wig", "zip", "zoo",
	"arm", "art", "bay", "bed", "box", "boy", "bud", "bun", "cap", "cog",
	"dam", "den", "dew", "dig", "dip", "dot", "egg", "elf", "elm", "era",
	"fan", "fat", "fin", "fit", "fly", "fog", "fun", "fur", "gap", "gas"
]

const MIN_GUESS_INTERVAL := 2.0
const MAX_GUESS_INTERVAL := 8.0
const CORRECT_GUESS_CHANCE := 0.3
const MIN_TIME_FOR_CORRECT := 5.0
const MAX_AI_COUNT := 8

## Emitted whenever an AI player submits a word or makes a guess.
## Routes through the same _on_player_guessed handler as real players.
signal ai_guessed(word: String, player_ui: DrawPlayerUI)

@export var player_list: PlayerList
@export var pet_spawner: DrawGuessPetSpawner
@export var word_manager: DrawGuessWordManager
@export var round_manager: DrawGuessRoundManager
@export var scoring: DrawGuessScoring

var _ai_players: Array[DrawAIPlayer] = []
var _is_prepare_phase := false
var _is_game_phase := false
var _current_round_word := ""
var _guess_timers: Dictionary = {}

var logger := KumaLog.new("DrawAIManager")


# ── Phase lifecycle ────────────────────────────────────────────────────────────

func on_prepare_phase_entered() -> void:
	_is_prepare_phase = true
	_is_game_phase = false
	_stop_all_guess_timers()
	# Auto-submit words for any AI already present
	for ai in _ai_players:
		_submit_word(ai)


func on_game_phase_entered() -> void:
	_is_prepare_phase = false
	_is_game_phase = true
	# Initialise scoring for all current AI players
	for ai in _ai_players:
		scoring.init_player(ai.uuid)


func start_game_round(word: String) -> void:
	_current_round_word = word
	for ai in _ai_players:
		if not round_manager.has_guessed(ai.uuid) and not round_manager.is_word_owner(ai.uuid):
			_schedule_guess(ai)


func stop_guessing() -> void:
	_is_game_phase = false
	_stop_all_guess_timers()


# ── AI count management (prepare phase only) ───────────────────────────────────

func increase_ai_count() -> void:
	if not _is_prepare_phase:
		return
	_set_ai_count(_ai_players.size() + 1)


func decrease_ai_count() -> void:
	if not _is_prepare_phase:
		return
	_set_ai_count(_ai_players.size() - 1)


func get_ai_count() -> int:
	return _ai_players.size()


## Set absolute AI count from external source (e.g. GameSettings autoload).
## Safe to call from any phase — no‑ops when not in prepare phase.
func set_ai_count(count: int) -> void:
	if not _is_prepare_phase:
		return
	_set_ai_count(count)


func _set_ai_count(count: int) -> void:
	var new_count := clampi(count, 0, MAX_AI_COUNT)
	while _ai_players.size() > new_count:
		_remove_last_ai()
	while _ai_players.size() < new_count:
		_add_ai()
	player_list.extra_player_count = _ai_players.size()


# ── Internal: add / remove a single AI ────────────────────────────────────────

func _add_ai() -> void:
	var ai_idx := PlayerManager.get_active_players().size() + _ai_players.size()
	# Use a time-based suffix so UUIDs stay unique across add/remove cycles
	var uuid := "ai_%d_%d" % [_ai_players.size(), Time.get_ticks_msec()]
	var color := PlayerList.get_color(ai_idx)

	var ai_ui := DRAW_AI_PLAYER_SCENE.instantiate() as DrawAIPlayer
	player_list.add_child(ai_ui)
	ai_ui.ready_updated.connect(func(): player_list.ready_changed.emit())
	ai_ui.setup_ai(ai_idx, uuid, color)

	# Keep the player list from evicting AI nodes during its own refresh
	player_list.persistent_uuids.append(uuid)

	# Connect guess signal up to the main game handler
	ai_ui.guessed.connect(func(word: String): ai_guessed.emit(word, ai_ui))

	pet_spawner.spawn_for_ai(ai_idx, uuid, color)

	_ai_players.append(ai_ui)
	logger.info("AI player added: %s (idx %d)" % [uuid, ai_idx])

	if _is_prepare_phase:
		_submit_word(ai_ui)


func _remove_last_ai() -> void:
	if _ai_players.is_empty():
		return
	var ai_ui: DrawAIPlayer = _ai_players.pop_back()
	_cancel_guess_timer(ai_ui.uuid)
	player_list.persistent_uuids.erase(ai_ui.uuid)
	pet_spawner.remove_pet(ai_ui.uuid)
	ai_ui.move_out()
	logger.info("AI player removed: %s" % ai_ui.uuid)


# ── Word submission (prepare phase) ───────────────────────────────────────────

func _submit_word(ai: DrawAIPlayer) -> void:
	if word_manager.is_player_submitted(ai.uuid):
		return
	var attempts := 0
	while attempts < 20:
		var word: String = WORD_LIST[randi() % WORD_LIST.size()]
		var result := word_manager.submit_word(word, ai.uuid)
		if result == DrawGuessWordManager.SubmitResult.ACCEPTED:
			ai.mark_word_submitted()
			logger.info("AI %s submitted word" % ai.uuid)
			return
		attempts += 1
	logger.warn("AI %s could not find a unique word to submit" % ai.uuid)


# ── Guessing (game phase) ──────────────────────────────────────────────────────

func _schedule_guess(ai: DrawAIPlayer) -> void:
	_cancel_guess_timer(ai.uuid)
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = randf_range(MIN_GUESS_INTERVAL, MAX_GUESS_INTERVAL)
	timer.timeout.connect(_on_guess_timer.bind(ai))
	add_child(timer)
	timer.start()
	_guess_timers[ai.uuid] = timer


func _cancel_guess_timer(uuid: String) -> void:
	if _guess_timers.has(uuid):
		_guess_timers[uuid].queue_free()
		_guess_timers.erase(uuid)


func _stop_all_guess_timers() -> void:
	for uuid in _guess_timers.keys():
		if is_instance_valid(_guess_timers[uuid]):
			_guess_timers[uuid].queue_free()
	_guess_timers.clear()


func _on_guess_timer(ai: DrawAIPlayer) -> void:
	if not _is_game_phase:
		return
	if round_manager.has_guessed(ai.uuid):
		return
	if round_manager.is_word_owner(ai.uuid):
		return
	if round_manager.phase != DrawGuessRoundManager.Phase.DRAWING:
		return

	var elapsed := round_manager.get_elapsed_time()
	var can_guess_correct := elapsed >= MIN_TIME_FOR_CORRECT and randf() < CORRECT_GUESS_CHANCE

	if can_guess_correct:
		logger.debug("AI %s guessing correctly after %.1fs" % [ai.uuid, elapsed])
		ai_guessed.emit(_current_round_word, ai)
	else:
		var wrong_word := _get_random_wrong_word()
		logger.debug("AI %s wrong guess: %s" % [ai.uuid, wrong_word])
		ai_guessed.emit(wrong_word, ai)
		# Schedule another attempt
		_schedule_guess(ai)


func _get_random_wrong_word() -> String:
	var attempts := 0
	while attempts < 20:
		var word: String = WORD_LIST[randi() % WORD_LIST.size()]
		if word.to_lower() != _current_round_word.to_lower():
			return word
		attempts += 1
	return "wrong"
