class_name VortexAIManager
extends Node

## Manages AI-controlled mobile players for Vortex Volley. Mirrors
## DrawGuessAIManager: AI players appear in the shared player list, are driven by
## the global GameSettings AI count (Ctrl+Alt+Up/Down), and occupy paddles like
## real phone players. The count is only adjustable during the prepare phase.

const AI_PLAYER_SCENE := preload("res://mods-unpacked/KumaGee-VRCore/vortex-volley/vortex_ai_player.tscn")
const MAX_AI_COUNT := 8

var player_list: PlayerList = null
var arena: VortexArena = null

var _ai_players: Array[VortexAIPlayer] = []
## Typed as the base class so it can be handed straight to VortexArena.
var _controllers: Array[ClientController] = []
var _is_prepare_phase := false
var _game_settings_ai_prev := 0

var logger := KumaLog.new("VortexAIManager")

func setup(list: PlayerList, a: VortexArena) -> void:
	player_list = list
	arena = a

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
		(c as VortexAIController).start_gameplay()

## Stops AI gameplay (round over / leaving the game). AI players stay in the list
## so a restart can reuse them.
func stop() -> void:
	_is_prepare_phase = false
	_disconnect_settings()
	for c in _controllers:
		(c as VortexAIController).stop_gameplay()

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
	if arena:
		arena.set_ai_controllers(_controllers)

func _add_ai() -> void:
	var ai_idx := PlayerManager.get_active_players().size() + _ai_players.size()
	# Time-based suffix keeps UUIDs unique across add/remove cycles
	var uuid := "ai_%d_%d" % [_ai_players.size(), Time.get_ticks_msec()]
	var color := PlayerList.get_color(ai_idx)

	var controller := VortexAIController.new()
	controller.uuid = uuid
	controller.color_idx = ai_idx
	add_child(controller)

	var ai_ui := AI_PLAYER_SCENE.instantiate() as VortexAIPlayer
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
	var ai_ui: VortexAIPlayer = _ai_players.pop_back()
	var controller := _controllers.pop_back() as VortexAIController
	player_list.persistent_uuids.erase(ai_ui.uuid)
	if arena:
		# Resync first so the arena releases the paddle before the node is freed
		arena.set_ai_controllers(_controllers)
	ai_ui.leave()
	controller.queue_free()
	logger.info("AI player removed: %s" % ai_ui.uuid)
