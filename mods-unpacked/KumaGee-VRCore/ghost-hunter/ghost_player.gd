class_name GhostPlayer
extends CharacterBody3D

## GH-4: a phone-controlled ghost inside the haunted house. Moves with the
## phone joystick (screen up = world -Z, same mapping as the hide-and-seek
## hiders) and re-emits A/B as primary/secondary action signals for the
## GH-8/GH-10 slices. Visual meshes live on render layer 20, which only the
## desktop shared-screen cameras render, so the Hunter's VR camera cannot
## see ghosts with the naked eye. GH-6: the Flash Device briefly adds the
## Hunter's render layer (layer 1) plus a bright highlight while the ghost
## is revealed.

signal primary_action_pressed()
signal secondary_action_pressed()
signal revealed(ghost: GhostPlayer)
signal haunt_purged(ghost: GhostPlayer)

const MOVE_DEADZONE: float = 0.15
const LAYER_SHARED := 1 << 19 # layer 20: shared-screen cameras only
const LAYER_HUNTER := 1 # layer 1: also rendered by the Hunter's VR camera
const REVEAL_EMISSION_ENERGY := 2.5
## Height of the body center above the feet (matches the capsule/mesh offset
## in ghost_player.tscn).
const BODY_CENTER_HEIGHT := 0.6

@export var speed: float = 2.5
@export var acceleration: float = 10.0
@export var turn_speed: float = 12.0

var controller: ClientController

## GH-8 states: a phasing ghost (inside a wall) and a haunting ghost (inside
## an object) stay invisible to the Hunter even while flash-revealed.
var is_phasing := false
var haunted_object: Node3D = null

var color: Color = Color.WHITE:
	set(v):
		color = v
		_apply_color()

@onready var _body_mesh: MeshInstance3D = %BodyMesh

var _reveal_timer := 0.0
var _meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
	_apply_color()
	_apply_hunter_visibility()


func _process(delta: float) -> void:
	if _reveal_timer > 0.0:
		_reveal_timer = maxf(0.0, _reveal_timer - delta)
		if _reveal_timer == 0.0:
			_apply_hunter_visibility()


## Wires the owning phone/gamepad controller, assigns the player color, and
## places the ghost at the given interior spawn point.
func setup(p_controller: ClientController, p_color: Color, spawn_pos: Vector3) -> void:
	controller = p_controller
	color = p_color
	global_position = spawn_pos
	if controller:
		controller.primary_action_pressed.connect(_on_primary_action)
		controller.secondary_action_pressed.connect(_on_secondary_action)


func _exit_tree() -> void:
	if controller:
		if controller.primary_action_pressed.is_connected(_on_primary_action):
			controller.primary_action_pressed.disconnect(_on_primary_action)
		if controller.secondary_action_pressed.is_connected(_on_secondary_action):
			controller.secondary_action_pressed.disconnect(_on_secondary_action)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	var input := _current_move_input()
	var target_vel := Vector3(input.x, 0.0, input.y) * speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	if horiz.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(horiz.x, horiz.z), turn_speed * delta)

	move_and_slide()


func _current_move_input() -> Vector2:
	# Poll the live joystick value so continuous input and release-to-zero work.
	var input: Vector2 = controller.get_move() if controller else Vector2.ZERO
	if input.length() < MOVE_DEADZONE:
		return Vector2.ZERO
	return input


## GH-6: marks the ghost revealed to the Hunter for [duration] seconds.
func set_revealed(duration: float) -> void:
	_reveal_timer = maxf(_reveal_timer, duration)
	_apply_hunter_visibility()
	revealed.emit(self)


func is_revealed() -> bool:
	return _reveal_timer > 0.0


func is_haunting() -> bool:
	return haunted_object != null


## Center of the ghost body in world space. Flash line-of-sight rays target
## this instead of the feet, which sit exactly on the floor plane.
func get_body_center() -> Vector3:
	return global_position + Vector3.UP * BODY_CENTER_HEIGHT


## GH-6 purge hook: the Flash Device forces the ghost out of the object it
## is possessing (GH-8) and places it at the object's position.
func purge_haunt() -> void:
	if haunted_object == null:
		return
	global_position = haunted_object.global_position
	haunted_object = null
	haunt_purged.emit(self)
	_apply_hunter_visibility()


func is_visible_to_hunter() -> bool:
	return is_revealed() and not is_phasing and not is_haunting()


## Debug/E2E helper: teleport the ghost (the MCP bridge cannot pass Vector3).
## Also resets velocity so a falling ghost doesn't plummet right back down.
func debug_teleport(x: float, y: float, z: float) -> void:
	global_position = Vector3(x, y, z)
	velocity = Vector3.ZERO


## Debug/E2E helper: mark the ghost as haunting the node at [object_path]
## (GH-8 will own the real haunt state).
func debug_set_haunting(object_path: String) -> void:
	haunted_object = get_node_or_null(object_path)
	_apply_hunter_visibility()


func _apply_color() -> void:
	if not _body_mesh:
		return
	var mat := _body_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
		mat.emission = color
		mat.emission_energy_multiplier = 0.4


## Ghosts render on the shared-screen layer only, unless flash-revealed (and
## not phasing/haunting), in which case the Hunter's VR layer is added and
## the body gets a bright highlight.
func _apply_hunter_visibility() -> void:
	var visible := is_visible_to_hunter()
	for mesh in _meshes:
		if visible:
			mesh.layers = LAYER_SHARED | LAYER_HUNTER
		else:
			mesh.layers = LAYER_SHARED
	if _body_mesh:
		var mat := _body_mesh.material_override as StandardMaterial3D
		if mat:
			if visible:
				mat.emission = color
				mat.emission_energy_multiplier = REVEAL_EMISSION_ENERGY
			else:
				_apply_color()


func _on_primary_action() -> void:
	primary_action_pressed.emit()


func _on_secondary_action() -> void:
	secondary_action_pressed.emit()
