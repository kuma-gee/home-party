class_name HideAndSeekHider
extends Node

## Represents a mobile hider player in Hide & Seek.
## Manages prop selection, movement, distract, and swap.

signal prop_selected(prop: XRToolsPickable)
signal prop_moved(pos: Vector3)
signal found()
signal distracted()
signal swapped(old_prop: XRToolsPickable, new_prop: XRToolsPickable)
signal cooldowns_updated(distract: float, swap: float, swap_blocked: float)

const DISTRACT_COOLDOWN: float = 10.0
const SWAP_COOLDOWN: float = 20.0
const SWAP_BLOCK_AFTER_DISTRACT: float = 5.0

var controller: ClientController
var current_prop: XRToolsPickable
var original_prop: XRToolsPickable
var player_name: String = ""
var is_found: bool = false
var is_held: bool = false
var move_input: Vector2 = Vector2.ZERO
var move_speed: float = 3.0

var distract_cooldown: float = 0.0
var swap_cooldown: float = 0.0
var swap_blocked_until: float = 0.0
var distract_count: int = 0

var props_manager: HideAndSeekProps
var distract_system: DistractSystem


func _process(delta: float) -> void:
	var changed := false
	if distract_cooldown > 0.0:
		distract_cooldown -= delta
		if distract_cooldown < 0.0:
			distract_cooldown = 0.0
		changed = true
	if swap_cooldown > 0.0:
		swap_cooldown -= delta
		if swap_cooldown < 0.0:
			swap_cooldown = 0.0
		changed = true
	if swap_blocked_until > 0.0:
		swap_blocked_until -= delta
		if swap_blocked_until < 0.0:
			swap_blocked_until = 0.0
		changed = true

	if changed:
		cooldowns_updated.emit(distract_cooldown, swap_cooldown, swap_blocked_until)

	if current_prop and not is_found and not is_held:
		_move_prop(delta)


func select_prop(prop: XRToolsPickable) -> void:
	if current_prop and current_prop != prop:
		current_prop.visible = true
		current_prop.enabled = true
		current_prop.collision_layer = 5
		current_prop.collision_mask = 1
		current_prop.freeze = true

	current_prop = prop
	original_prop = prop
	is_found = false
	is_held = false

	prop.visible = true
	prop.enabled = true
	prop.collision_layer = 5
	prop.collision_mask = 1
	prop.freeze = false

	prop_selected.emit(prop)


func swap_to_prop(new_prop: XRToolsPickable) -> bool:
	if is_found or is_held:
		return false
	if swap_cooldown > 0.0:
		return false
	if swap_blocked_until > 0.0:
		return false
	if new_prop == current_prop:
		return false
	if not new_prop or not new_prop.visible:
		return false

	var old_prop := current_prop

	if old_prop:
		old_prop.visible = true
		old_prop.enabled = true
		old_prop.collision_layer = 5
		old_prop.collision_mask = 1
		old_prop.freeze = true
		if props_manager:
			old_prop.global_transform = props_manager.get_initial_transform(old_prop)

	current_prop = new_prop
	current_prop.visible = true
	current_prop.enabled = true
	current_prop.collision_layer = 5
	current_prop.collision_mask = 1
	current_prop.freeze = false

	swap_cooldown = SWAP_COOLDOWN

	swapped.emit(old_prop, new_prop)
	cooldowns_updated.emit(distract_cooldown, swap_cooldown, swap_blocked_until)

	return true


func mark_as_held(held: bool) -> void:
	is_held = held


func mark_as_found() -> void:
	is_found = true
	if current_prop:
		current_prop.visible = false
		current_prop.enabled = false
		current_prop.collision_layer = 0
		current_prop.collision_mask = 0
		current_prop.freeze = true
	found.emit()


func reset() -> void:
	if current_prop and original_prop:
		current_prop.visible = true
		current_prop.enabled = true
		current_prop.collision_layer = 5
		current_prop.collision_mask = 1
		current_prop.freeze = true

	current_prop = null
	original_prop = null
	is_found = false
	is_held = false
	move_input = Vector2.ZERO
	distract_cooldown = 0.0
	swap_cooldown = 0.0
	swap_blocked_until = 0.0
	distract_count = 0


func _on_action_pressed() -> void:
	if is_found or is_held:
		return


func _on_action_released() -> void:
	if is_found or is_held:
		return


func _on_secondary_pressed() -> void:
	if is_found or is_held:
		return
	if distract_cooldown > 0.0:
		return
	if swap_blocked_until > 0.0:
		return
	_distract()


func _on_moved(dir: Vector2) -> void:
	move_input = dir


func _distract() -> void:
	distract_cooldown = DISTRACT_COOLDOWN
	swap_blocked_until = SWAP_BLOCK_AFTER_DISTRACT
	distract_count += 1

	if current_prop and distract_system:
		distract_system.play_distract(current_prop.global_position)

	distracted.emit()
	cooldowns_updated.emit(distract_cooldown, swap_cooldown, swap_blocked_until)


func _move_prop(delta: float) -> void:
	if move_input.length() < 0.1:
		return

	var move_dir := Vector3(move_input.x, 0.0, move_input.y).normalized()
	var new_pos := current_prop.global_position + move_dir * move_speed * delta

	new_pos.x = clampf(new_pos.x, -2.5, 2.5)
	new_pos.z = clampf(new_pos.z, -2.5, 1.5)
	new_pos.y = 0.0

	current_prop.global_position = new_pos
	current_prop.linear_velocity = Vector3.ZERO
	current_prop.angular_velocity = Vector3.ZERO
