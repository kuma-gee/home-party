class_name HideAndSeekHider
extends Node

## Represents a mobile hider player in Hide & Seek.
## Manages their prop selection, movement, distract, and swap.

signal prop_selected(prop: XRToolsPickable)
signal prop_moved(position: Vector3)
signal found()
signal distracted()
signal swapped(old_prop: XRToolsPickable, new_prop: XRToolsPickable)
signal cooldowns_updated(distract: float, swap: float, swap_blocked: float)

## The mobile player's controller
var controller: ClientController

## The prop this hider is currently controlling
var current_prop: XRToolsPickable = null

## The prop they were originally (for reset)
var original_prop: XRToolsPickable = null

## Player name/UUID
var player_name: String = ""

## Whether this hider has been found
var is_found: bool = false

## Whether this hider is currently held by the VR player
var is_held: bool = false

## Hunt phase: movement input
var move_input: Vector2 = Vector2.ZERO

## Movement speed (meters per second)
var move_speed: float = 3.0

## Cooldowns
var distract_cooldown: float = 0.0
var swap_cooldown: float = 0.0
var swap_blocked_until: float = 0.0  # Can't swap for 5s after distract

## Cooldown durations
const DISTRACT_COOLDOWN: float = 10.0
const SWAP_COOLDOWN: float = 20.0
const SWAP_BLOCK_AFTER_DISTRACT: float = 5.0

## Stats
var distract_count: int = 0

## Reference to props manager for finding nearest prop
var props_manager: HideAndSeekProps = null

## Reference to distract system
var distract_system: DistractSystem = null

func _ready() -> void:
	if controller:
		controller.primary_action_pressed.connect(_on_action_pressed)
		controller.secondary_action_pressed.connect(_on_secondary_pressed)
		controller.moved.connect(_on_moved)

func _process(delta: float) -> void:
	# Update cooldowns
	var changed = false
	if distract_cooldown > 0:
		distract_cooldown -= delta
		if distract_cooldown < 0:
			distract_cooldown = 0
		changed = true
	if swap_cooldown > 0:
		swap_cooldown -= delta
		if swap_cooldown < 0:
			swap_cooldown = 0
		changed = true
	if swap_blocked_until > 0:
		swap_blocked_until -= delta
		if swap_blocked_until < 0:
			swap_blocked_until = 0
		changed = true
	
	if changed:
		cooldowns_updated.emit(distract_cooldown, swap_cooldown, swap_blocked_until)
	
	# Move the prop during hunt phase
	if current_prop and not is_found and not is_held:
		_move_prop(delta)

func _on_action_pressed() -> void:
	"""Button A pressed - start highlighting for swap."""
	if is_found or is_held:
		return
	# Highlighting is handled on the client side

func _on_action_released() -> void:
	"""Button A released - attempt to swap."""
	if is_found or is_held:
		return
	# Swap is handled on the client side via server

func _on_secondary_pressed() -> void:
	"""Button B pressed - distract."""
	if is_found or is_held:
		return
	if distract_cooldown > 0:
		return
	if swap_blocked_until > 0:
		return  # Can't distract if swap is blocked (this is backwards, but keeping simple)
	
	_distract()

func _distract() -> void:
	"""Emit a distract sound."""
	distract_cooldown = DISTRACT_COOLDOWN
	swap_blocked_until = SWAP_BLOCK_AFTER_DISTRACT
	distract_count += 1
	
	if current_prop and distract_system:
		distract_system.play_distract(current_prop.global_position)
	
	distracted.emit()
	cooldowns_updated.emit(distract_cooldown, swap_cooldown, swap_blocked_until)

func _on_moved(dir: Vector2) -> void:
	"""Joystick movement input."""
	move_input = dir

func _move_prop(delta: float) -> void:
	"""Move the current prop based on joystick input."""
	if move_input.length() < 0.1:
		return
	
	var move_dir = Vector3(move_input.x, 0, move_input.y).normalized()
	var new_pos = current_prop.global_position + move_dir * move_speed * delta
	
	# Keep within room bounds (approximate)
	new_pos.x = clampf(new_pos.x, -2.5, 2.5)
	new_pos.z = clampf(new_pos.z, -2.5, 1.5)
	new_pos.y = 0  # Keep on ground
	
	current_prop.global_position = new_pos
	current_prop.linear_velocity = Vector3.ZERO
	current_prop.angular_velocity = Vector3.ZERO

func select_prop(prop: XRToolsPickable) -> void:
	"""Select a prop to hide as."""
	if current_prop and current_prop != prop:
		# Deselect previous prop - restore it to static
		current_prop.visible = true
		current_prop.enabled = true
		current_prop.collision_layer = 5
		current_prop.collision_mask = 1
		current_prop.freeze = true
	
	current_prop = prop
	original_prop = prop
	is_found = false
	is_held = false
	
	# The prop remains visible and controlled by this hider
	prop.visible = true
	prop.enabled = true
	prop.collision_layer = 5
	prop.collision_mask = 1
	prop.freeze = false
	
	prop_selected.emit(prop)

func swap_to_prop(new_prop: XRToolsPickable) -> bool:
	"""Swap to a new prop. Returns true if successful."""
	if is_found or is_held:
		return false
	if swap_cooldown > 0:
		return false
	if swap_blocked_until > 0:
		return false
	if new_prop == current_prop:
		return false
	if not new_prop or not new_prop.visible:
		return false
	
	var old_prop = current_prop
	
	# Restore old prop to static state
	if old_prop:
		old_prop.visible = true
		old_prop.enabled = true
		old_prop.collision_layer = 5
		old_prop.collision_mask = 1
		old_prop.freeze = true
		old_prop.global_transform = _get_initial_transform(old_prop)
	
	# Take control of new prop
	current_prop = new_prop
	current_prop.visible = true
	current_prop.enabled = true
	current_prop.collision_layer = 5
	current_prop.collision_mask = 1
	current_prop.freeze = false
	
	# Start swap cooldown
	swap_cooldown = SWAP_COOLDOWN
	
	swapped.emit(old_prop, new_prop)
	cooldowns_updated.emit(distract_cooldown, swap_cooldown, swap_blocked_until)
	
	return true

func _get_initial_transform(prop: XRToolsPickable) -> Transform3D:
	"""Get the initial transform for a prop (for reset after swap)."""
	if props_manager and props_manager._initial_transforms.has(prop):
		return props_manager._initial_transforms[prop]
	return prop.global_transform

func mark_as_held(held: bool) -> void:
	"""Mark whether this hider is being held by the VR player."""
	is_held = held

func mark_as_found() -> void:
	"""Mark this hider as found."""
	is_found = true
	if current_prop:
		current_prop.visible = false
		current_prop.enabled = false
		current_prop.collision_layer = 0
		current_prop.collision_mask = 0
		current_prop.freeze = true
	found.emit()

func reset() -> void:
	"""Reset this hider to initial state."""
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
