class_name HideAndSeekGame
extends Node

## Manages the Hide & Seek game flow: mobile hiders, scoring, and round reset.

signal phase_changed(new_phase: Phase)
signal setup_timer_updated(time: float)
signal hunt_timer_updated(time: float)
signal hider_joined(hider: HideAndSeekHider)
signal hider_left(hider: HideAndSeekHider)
signal round_ended(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary])

enum Phase {
	WAITING,
	SETUP,
	HUNT,
	ENDED,
}

@export var setup_duration: float = 8.0
@export var hunt_duration: float = 120.0

var phase: Phase = Phase.WAITING:
	set(v):
		phase = v
		phase_changed.emit(v)

var phase_timer: float = 0.0
var hiders: Array[HideAndSeekHider] = []
var props_manager: HideAndSeekProps
var distract_system: DistractSystem
var available_props: Array[XRToolsPickable] = []

var _total_hiders_at_start: int = 0
var _vr_score: int = 0


func _ready() -> void:
	PlayerManager.clients_changed.connect(_on_clients_changed)
	phase_changed.connect(_on_phase_changed)


func _process(delta: float) -> void:
	if phase == Phase.SETUP:
		phase_timer -= delta
		setup_timer_updated.emit(maxf(phase_timer, 0.0))
		if phase_timer <= 0.0:
			_start_hunt()
	elif phase == Phase.HUNT:
		phase_timer -= delta
		hunt_timer_updated.emit(maxf(phase_timer, 0.0))
		if phase_timer <= 0.0:
			end_round(false)
		_update_hider_movement(delta)


func end_round(vr_won: bool) -> void:
	phase = Phase.ENDED

	_vr_score = _calculate_vr_score(vr_won)
	var hider_scores := _calculate_hider_scores(vr_won)

	var result_msg := JSON.stringify({
		"type": "found",
		"message": "You survived!" if not vr_won else "You've been found!",
		"vr_won": vr_won,
	})
	_send_to_all_mobiles(result_msg)

	round_ended.emit(vr_won, _vr_score, hider_scores)
	print("[HideAndSeek] Round ended - VR %s (Score: %d)" % ["won" if vr_won else "lost", _vr_score])


func reset_for_new_round() -> void:
	_cleanup_round()
	phase = Phase.WAITING
	_total_hiders_at_start = 0
	_vr_score = 0


func get_hider_count() -> int:
	return _get_active_hider_count()


func get_found_count() -> int:
	var count := 0
	for hider in hiders:
		if hider.is_found:
			count += 1
	return count


func find_hider_by_prop(prop: XRToolsPickable) -> HideAndSeekHider:
	for hider in hiders:
		if hider.current_prop == prop:
			return hider
	return null


func find_nearest_prop(pos: Vector3, exclude: XRToolsPickable = null) -> XRToolsPickable:
	var nearest: XRToolsPickable = null
	var nearest_dist := INF

	for prop in available_props:
		if prop == exclude:
			continue
		if not prop.visible:
			continue
		var dist := pos.distance_to(prop.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = prop

	return nearest


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
	var hider := HideAndSeekHider.new()
	hider.controller = controller
	hider.player_name = controller.uuid
	hider.props_manager = props_manager
	hider.distract_system = distract_system
	add_child(hider)
	hiders.append(hider)
	hider_joined.emit(hider)

	controller.primary_action_pressed.connect(hider._on_action_pressed)
	controller.secondary_action_pressed.connect(hider._on_secondary_pressed)
	controller.moved.connect(hider._on_moved)

	hider.cooldowns_updated.connect(_on_hider_cooldowns_updated.bind(hider))
	hider.distracted.connect(_on_hider_distracted.bind(hider))


func _on_hider_cooldowns_updated(distract: float, swap: float, swap_blocked: float, hider: HideAndSeekHider) -> void:
	if hider.controller is GameClient:
		var gc := hider.controller as GameClient
		var msg := JSON.stringify({
			"type": "cooldowns",
			"distract": distract,
			"swap": swap,
			"swap_blocked": swap_blocked,
		})
		gc.send_text(msg)


func _on_hider_distracted(_hider: HideAndSeekHider) -> void:
	# Sound is played by the hider's distract method
	pass


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


func _prepare_setup() -> void:
	if props_manager:
		props_manager.freeze_all()
		available_props = props_manager.get_props()

	_send_to_all_mobiles(JSON.stringify({
		"type": "phase",
		"phase": "setup",
	}))
	_send_prop_positions_to_mobile()


func _prepare_hunt() -> void:
	_total_hiders_at_start = 0
	for hider in hiders:
		if hider.current_prop:
			_total_hiders_at_start += 1
			if props_manager:
				props_manager.mark_as_hider(hider.current_prop, hider.player_name)

	if props_manager:
		props_manager.unfreeze_all()

	_send_to_all_mobiles(JSON.stringify({
		"type": "phase",
		"phase": "hunt",
	}))


func _start_hunt() -> void:
	phase = Phase.HUNT


func _cleanup_round() -> void:
	if props_manager:
		props_manager.reset_all()
	for hider in hiders:
		hider.reset()


func _update_hider_movement(delta: float) -> void:
	for hider in hiders:
		if hider.current_prop and not hider.is_found and not hider.is_held:
			hider._move_prop(delta)


func _send_prop_positions_to_mobile() -> void:
	var prop_data := []
	for prop in available_props:
		if prop.visible:
			prop_data.append({
				"name": prop.name,
				"x": prop.global_position.x,
				"z": prop.global_position.z,
			})

	_send_to_all_mobiles(JSON.stringify({
		"type": "props",
		"props": prop_data,
	}))


func _send_to_all_mobiles(msg: String) -> void:
	for hider in hiders:
		if hider.controller is GameClient:
			var gc := hider.controller as GameClient
			gc.send_text(msg)


func _calculate_vr_score(vr_won: bool) -> int:
	var found_count := _total_hiders_at_start - _get_active_hider_count()
	var score := found_count
	if vr_won and _total_hiders_at_start > 0:
		score += 3
	return score


func _calculate_hider_scores(vr_won: bool) -> Array[Dictionary]:
	var scores: Array[Dictionary] = []
	var active_hiders := _get_active_hiders()
	var last_survivor: HideAndSeekHider = null

	if active_hiders.size() == 1:
		last_survivor = active_hiders[0]

	for hider in hiders:
		var survived := not hider.is_found and not vr_won
		var is_last := hider == last_survivor
		var score := 0
		if survived:
			score += 3
		if is_last:
			score += 2
		score += hider.distract_count

		scores.append({
			"name": hider.player_name,
			"score": score,
			"survived": survived,
			"last_survivor": is_last,
			"distracts": hider.distract_count,
		})

	return scores


func _get_active_hider_count() -> int:
	var count := 0
	for hider in hiders:
		if not hider.is_found:
			count += 1
	return count


func _get_active_hiders() -> Array[HideAndSeekHider]:
	var result: Array[HideAndSeekHider] = []
	for hider in hiders:
		if not hider.is_found:
			result.append(hider)
	return result
