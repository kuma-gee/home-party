class_name HideAndSeekGame
extends Node

## Manages the social-deduction Hide & Seek round flow: hider sync, phase
## timers, seeker tag/scan scoring, and round-end scoreboard data.

signal phase_changed(new_phase: Phase)
signal setup_timer_updated(time: float)
signal hunt_timer_updated(time: float)
signal hider_joined(hider: HiderCharacter)
signal hider_left(hider: HiderCharacter)
signal hider_found(hider: HiderCharacter)
signal round_ended(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary])

enum Phase {
	WAITING,
	SETUP,
	HUNT,
	ENDED,
}

@export var setup_duration: float = 10.0
@export var hunt_duration: float = 90.0

@export var hider_scene: PackedScene
@export var hider_spawn_area: Node3D
@export var npc_spawner: NpcSpawner

var phase: Phase = Phase.WAITING:
	set(v):
		phase = v
		phase_changed.emit(v)

var phase_timer: float = 0.0
var hiders: Array[HiderCharacter] = []
var interactive_locations: Array[InteractiveLocation] = []

var _total_hiders_at_start: int = 0
var _vr_score: int = 0
var _hider_spawn_index: int = 0


func _ready() -> void:
	PlayerManager.clients_changed.connect(_on_clients_changed)
	phase_changed.connect(_on_phase_changed)


func _process(delta: float) -> void:
	match phase:
		Phase.SETUP:
			phase_timer -= delta
			setup_timer_updated.emit(maxf(phase_timer, 0.0))
			if phase_timer <= 0.0:
				_start_hunt()
		Phase.HUNT:
			phase_timer -= delta
			hunt_timer_updated.emit(maxf(phase_timer, 0.0))
			if phase_timer <= 0.0:
				end_round(false)


func end_round(vr_won: bool) -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED

	# +5 bonus if the Seeker tagged every hider.
	if vr_won and _total_hiders_at_start > 0:
		_vr_score += 5

	var hider_scores := _calculate_hider_scores(vr_won)

	_send_to_all_mobiles(JSON.stringify({
		"type": "phase",
		"phase": "ended",
		"vr_won": vr_won,
	}))

	round_ended.emit(vr_won, _vr_score, hider_scores)
	print("[HideAndSeek] Round ended - VR %s (Score: %d)" % ["won" if vr_won else "lost", _vr_score])


func reset_for_new_round() -> void:
	_cleanup_round()
	phase = Phase.WAITING
	_vr_score = 0
	_total_hiders_at_start = 0


func get_hider_count() -> int:
	return _get_active_hider_count()


func get_hiders() -> Array[HiderCharacter]:
	return hiders


func get_hider_statuses() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for hider in hiders:
		out.append({
			"name": hider.player_name,
			"alive": not hider.is_found,
		})
	return out


func on_hider_tagged(hider: HiderCharacter) -> void:
	if not is_instance_valid(hider) or hider.is_found:
		return
	hider.mark_found()
	_vr_score += 2
	hider_found.emit(hider)
	_send_to_mobile(hider, JSON.stringify({
		"type": "found",
		"message": "You've been found!",
	}))
	if _get_active_hider_count() == 0:
		end_round(true)


func on_wrong_tag(npc: NpcCharacter) -> void:
	_vr_score -= 1
	if npc_spawner and is_instance_valid(npc):
		npc_spawner.scatter(npc.global_position, 8.0, 2.0)


func _on_clients_changed() -> void:
	_sync_hiders()


func _sync_hiders() -> void:
	var active_players := PlayerManager.get_active_players()

	var i := 0
	while i < hiders.size():
		var hider := hiders[i]
		if not active_players.has(hider.controller):
			hiders.remove_at(i)
			hider_left.emit(hider)
			hider.queue_free()
		else:
			i += 1

	for player in active_players:
		var exists := false
		for hider in hiders:
			if hider.controller == player:
				exists = true
				break
		if not exists:
			_add_hider(player)


func _add_hider(controller: ClientController) -> void:
	if not hider_scene:
		push_warning("HideAndSeekGame: no hider_scene set")
		return
	var hider := hider_scene.instantiate() as HiderCharacter
	if not hider:
		return
	add_child(hider)
	hider.controller = controller
	hider.player_name = controller.uuid
	# Hiders are frozen unless the round is already in the HUNT phase (late
	# joiners can move immediately; setup-time joiners are unfrozen when HUNT
	# begins via _prepare_hunt).
	hider.frozen = phase != Phase.HUNT
	if phase == Phase.SETUP:
		hider.set_identity_marker_visible(true)
	hider.global_position = _next_hider_spawn()
	hider.register_locations(interactive_locations)
	hiders.append(hider)
	hider_joined.emit(hider)

	controller.moved.connect(hider._on_moved)
	controller.primary_action_pressed.connect(hider._on_action_pressed)


func _next_hider_spawn() -> Vector3:
	if hider_spawn_area:
		var markers: Array[Node] = hider_spawn_area.get_children()
		var valid_markers: Array[Marker3D] = []
		for c in markers:
			if c is Marker3D:
				valid_markers.append(c as Marker3D)
		if not valid_markers.is_empty():
			var pos := valid_markers[_hider_spawn_index % valid_markers.size()].global_position
			_hider_spawn_index += 1
			return pos
	return Vector3.ZERO


func _on_phase_changed(new_phase: Phase) -> void:
	match new_phase:
		Phase.SETUP:
			phase_timer = setup_duration
			_prepare_setup()
		Phase.HUNT:
			phase_timer = hunt_duration
			_prepare_hunt()
		Phase.ENDED:
			_cleanup_round()


func _start_hunt() -> void:
	phase = Phase.HUNT


func _prepare_setup() -> void:
	for hider in hiders:
		hider.frozen = true
		hider.set_identity_marker_visible(true)
	_send_to_all_mobiles(JSON.stringify({
		"type": "phase",
		"phase": "setup",
	}))


func _prepare_hunt() -> void:
	_total_hiders_at_start = hiders.size()
	for hider in hiders:
		hider.frozen = false
		hider.set_identity_marker_visible(false)
	_send_to_all_mobiles(JSON.stringify({
		"type": "phase",
		"phase": "hunt",
	}))


func _cleanup_round() -> void:
	for hider in hiders:
		if is_instance_valid(hider):
			hider.set_identity_marker_visible(false)


func _calculate_hider_scores(vr_won: bool) -> Array[Dictionary]:
	var scores: Array[Dictionary] = []
	var active := _get_active_hiders()
	var last_survivor: HiderCharacter = null
	if active.size() == 1 and not vr_won:
		last_survivor = active[0]

	for hider in hiders:
		var survived := not hider.is_found and not vr_won
		var is_last := hider == last_survivor
		var score := 0
		if survived:
			score += 3
		if is_last:
			score += 4
		scores.append({
			"name": hider.player_name,
			"score": score,
			"survived": survived,
			"last_survivor": is_last,
		})
	return scores


func _get_active_hider_count() -> int:
	var count := 0
	for hider in hiders:
		if is_instance_valid(hider) and not hider.is_found:
			count += 1
	return count


func _get_active_hiders() -> Array[HiderCharacter]:
	var out: Array[HiderCharacter] = []
	for hider in hiders:
		if is_instance_valid(hider) and not hider.is_found:
			out.append(hider)
	return out


func _send_to_mobile(hider: HiderCharacter, msg: String) -> void:
	if hider.controller is GameClient:
		(hider.controller as GameClient).send_text(msg)


func _send_to_all_mobiles(msg: String) -> void:
	for hider in hiders:
		_send_to_mobile(hider, msg)
