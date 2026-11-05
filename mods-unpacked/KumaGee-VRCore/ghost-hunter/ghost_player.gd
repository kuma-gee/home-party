class_name GhostPlayer
extends CharacterBody3D

## GH-4: a phone-controlled ghost inside the haunted house. Moves with the
## phone joystick (screen up = world -Z, same mapping as the hide-and-seek
## hiders) and re-emits A/B as primary/secondary action signals for the
## GH-8/GH-10 slices. Visual meshes are on render layer 20, which only the
## desktop shared-screen cameras render, so the Hunter's VR camera cannot
## see ghosts with the naked eye (the GH-8 flash reveal will show them).

signal primary_action_pressed()
signal secondary_action_pressed()

const MOVE_DEADZONE: float = 0.15

@export var speed: float = 2.5
@export var acceleration: float = 10.0
@export var turn_speed: float = 12.0

var controller: ClientController

var color: Color = Color.WHITE:
	set(v):
		color = v
		_apply_color()

@onready var _body_mesh: MeshInstance3D = %BodyMesh


func _ready() -> void:
	_apply_color()


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


func _apply_color() -> void:
	if not _body_mesh:
		return
	var mat := _body_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
		mat.emission = color
		mat.emission_energy_multiplier = 0.4


func _on_primary_action() -> void:
	primary_action_pressed.emit()


func _on_secondary_action() -> void:
	secondary_action_pressed.emit()
