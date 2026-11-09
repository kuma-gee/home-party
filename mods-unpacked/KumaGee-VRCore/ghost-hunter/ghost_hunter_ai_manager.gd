class_name GhostHunterAIManager
extends Node

## Manages AI-controlled ghost players for Ghost Hunter. Mirrors
## VortexAIManager: AI players appear in the shared player list during the
## prepare phase, driven by the global GameSettings AI count
## (Ctrl+Alt+Up/Down) or the in-world bot count panel, and their ghosts are
## spawned with everyone else when the game phase starts. The count is only
## adjustable during the prepare phase.

const AI_PLAYER_SCENE := preload("res://mods-unpacked/KumaGee-VRCore/ghost-hunter/ghost_hunter_ai_player.tscn")
const MAX_AI_COUNT := 8

var player_list: PlayerList = null
## Returns the Hunter's world position (AI ghosts steer away from it).
var hunter_position_getter: Callable = Callable()
## Returns the game's task array (AI ghosts occasionally channel these).
var tasks_getter: Callable = Callable()
## Interior wander targets handed to every AI controller (house task/haunt spots).
var wander_targets: Array[Vector3] = []

var _ai_players: Array[GhostHunterAIPlayer] = []
## Typed as the base class so it can be handed straight to the game scene.
var _controllers: Array[ClientController] = []
## Task dicts claimed by any AI ghost; shared with every controller so
## multiple ghosts pick different task markers.
var _claimed_tasks: Array = []
var _is_prepare_phase := false
var _game_settings_ai_prev := 0

var logger := KumaLog.new("GhostHunterAIManager")

func setup(list: PlayerList, hunter_pos_getter: Callable) -> void:
	player_list = list
	hunter_position_getter = hunter_pos_getter

# ── Phase lifecycle ────────────────────────────────────────────────────────────

func on_prepare_phase_entered() -> void:
	_is_prepare_phase = true
	_game_settings_ai_prev = GameSettings.get_ai_count()
	if not GameSettings.ai_count_changed.is_connected(_on_game_settings_ai_count_changed):
		GameSettings.ai_count_changed.connect(_on_game_settings_ai_count_changed)
	_set_ai_count(_game_settings_ai_prev)

func on_game_phase_entered() -> void:
	_is_prepare_phase = false
	_disconnect_settings()
	for c in _controllers:
		(c as GhostHunterAIController).start_gameplay()

## Stops AI gameplay (round over / leaving the game). AI players stay in the
## list so a restart can reuse them.
func stop() -> void:
	_is_prepare_phase = false
	_disconnect_settings()
	for c in _controllers:
		(c as GhostHunterAIController).stop_gameplay()

func _disconnect_settings() -> void:
	if GameSettings.ai_count_changed.is_connected(_on_game_settings_ai_count_changed):
		GameSettings.ai_count_changed.disconnect(_on_game_settings_ai_count_changed)

func _on_game_settings_ai_count_changed(new_count: int) -> void:
	if not _is_prepare_phase:
		return
	_game_settings_ai_prev = new_count
	_set_ai_count(new_count)

# ── AI count management ────────────────────────────────────────────────────────

func get_ai_count() -> int:
	return _ai_players.size()

## Controllers backing the AI players, for the game scene to spawn ghosts for.
func get_ai_controllers() -> Array[ClientController]:
	return _controllers

func set_wander_targets(targets: Array[Vector3]) -> void:
	wander_targets = targets
	for c in _controllers:
		(c as GhostHunterAIController).set_wander_targets(targets)

func set_tasks_getter(getter: Callable) -> void:
	tasks_getter = getter
	for c in _controllers:
		(c as GhostHunterAIController).tasks_getter = getter

func _set_ai_count(count: int) -> void:
	var new_count := clampi(count, 0, MAX_AI_COUNT)
	while _ai_players.size() > new_count:
		_remove_last_ai()
	while _ai_players.size() < new_count:
		_add_ai()
	if player_list:
		player_list.extra_player_count = _ai_players.size()
		# extra_player_count changed after the per-bot ready_changed signals, so
		# re-emit to refresh ready displays and re-check the start condition.
		player_list.ready_changed.emit()

func _add_ai() -> void:
	var ai_idx := PlayerManager.get_active_players().size() + _ai_players.size()
	# Time-based suffix keeps UUIDs unique across add/remove cycles
	var uuid := "ai_%d_%d" % [_ai_players.size(), Time.get_ticks_msec()]
	var color := PlayerList.get_color(ai_idx)

	var controller := GhostHunterAIController.new()
	controller.uuid = uuid
	controller.color_idx = ai_idx
	controller.hunter_position_getter = hunter_position_getter
	controller.tasks_getter = tasks_getter
	controller.claimed_tasks = _claimed_tasks
	controller.set_wander_targets(wander_targets)
	add_child(controller)

	var ai_ui := AI_PLAYER_SCENE.instantiate() as GhostHunterAIPlayer
	player_list.add_child(ai_ui)
	ai_ui.ready_updated.connect(func(): player_list.ready_changed.emit())
	ai_ui.setup_ai(ai_idx, uuid, color)

	# Keep the player list from evicting AI nodes during its own refresh
	player_list.persistent_uuids.append(uuid)

	_ai_players.append(ai_ui)
	_controllers.append(controller)
	logger.info("AI player added: %s (idx %d)" % [uuid, ai_idx])

func _remove_last_ai() -> void:
	if _ai_players.is_empty():
		return
	var ai_ui: GhostHunterAIPlayer = _ai_players.pop_back()
	var controller := _controllers.pop_back() as GhostHunterAIController
	player_list.persistent_uuids.erase(ai_ui.uuid)
	controller.unbind_ghost()
	ai_ui.leave()
	controller.queue_free()
	logger.info("AI player removed: %s" % ai_ui.uuid)
