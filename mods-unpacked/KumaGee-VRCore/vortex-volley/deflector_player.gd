class_name DeflectorPlayer
extends CharacterBody3D

const MOVE_SPEED: float = 1.8
const CLAMP_FACTOR: float = 0.8
const PADDLE_RADIUS: float = 4.0

var controller: ClientController
var spawn: PlayerSpawn

@export var paddle_material: StandardMaterial3D
@export var paddle: MeshInstance3D
@export var goal_area: Area3D

var _move_input: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	goal_area.body_entered.connect(_on_goal_body_entered)
	paddle.material_override = paddle_material

## Links this paddle to the slot that owns its setup.
func bind(slot: PlayerSpawn) -> void:
	spawn = slot

## Reassigns this paddle to a controller (or releases it when null). Signal
## wiring follows the controller so pre-placed paddles are reused across rounds.
func set_controller(player: ClientController) -> void:
	if controller == player:
		return
	_disconnect_controller_signals()
	controller = player
	_move_input = Vector2.ZERO
	if controller:
		_connect_controller_signals()

## Enables/disables movement. Disabled while unassigned or eliminated.
func set_active(active: bool) -> void:
	_active = active
	if not active:
		velocity = Vector3.ZERO
		_move_input = Vector2.ZERO

func _connect_controller_signals() -> void:
	controller.moved.connect(_on_moved)
	controller.primary_action_pressed.connect(_on_launch)
	controller.secondary_action_pressed.connect(_on_launch)

func _disconnect_controller_signals() -> void:
	if controller:
		if controller.moved.is_connected(_on_moved):
			controller.moved.disconnect(_on_moved)
		if controller.primary_action_pressed.is_connected(_on_launch):
			controller.primary_action_pressed.disconnect(_on_launch)
		if controller.secondary_action_pressed.is_connected(_on_launch):
			controller.secondary_action_pressed.disconnect(_on_launch)

func _physics_process(_delta: float) -> void:
	if not _active or not spawn:
		return
	var input := controller.get_move() if controller else _move_input
	var tangent := _tangent()
	var side_half_length := spawn.arena_radius * tan(TAU / 16.0)
	var max_offset := side_half_length * CLAMP_FACTOR
	var offset := (global_position - _side_center()).dot(tangent)
	if (input.x > 0.0 and offset >= max_offset) or (input.x < 0.0 and offset <= -max_offset):
		input.x = 0.0
	velocity = tangent * input.x * MOVE_SPEED
	move_and_slide()

func _tangent() -> Vector3:
	return Vector3(-sin(spawn.base_angle), 0.0, cos(spawn.base_angle))

func _side_center() -> Vector3:
	return Vector3(
		cos(spawn.base_angle) * PADDLE_RADIUS,
		GameOrb.ORB_HEIGHT,
		sin(spawn.base_angle) * PADDLE_RADIUS
	)

func _on_moved(dir: Vector2) -> void:
	_move_input = dir

func _on_launch() -> void:
	if spawn:
		spawn.request_launch()

func _on_goal_body_entered(body: Node3D) -> void:
	if body is GameOrb and spawn:
		spawn.on_orb_passed(body)
