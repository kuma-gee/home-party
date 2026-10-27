class_name DeflectorPlayer
extends CharacterBody3D

const MOVE_SPEED: float = 1.8
const CLAMP_FACTOR: float = 0.8
const PADDLE_RADIUS: float = 4.0
## How far toward the arena center the ready orb floats in front of the paddle.
const HELD_ORB_OFFSET: float = 0.4

var controller: ClientController
var spawn: PlayerSpawn

@export var paddle_material: StandardMaterial3D
@export var paddle: MeshInstance3D
@export var goal_area: Area3D
## Visual-only orb shown while this player has a launchable orb.
@onready var held_orb: Node3D = $HeldOrb
@onready var held_orb_mesh: CSGSphere3D = $HeldOrb/Orb

var _move_input: Vector2 = Vector2.ZERO
var _active: bool = false
## Temporary Paddle Boost state: speed multiplier and remaining duration.
var _speed_boost_multiplier: float = 1.0
var _speed_boost_time: float = 0.0

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	goal_area.body_entered.connect(_on_goal_body_entered)
	paddle.material_override = paddle_material
	held_orb.visible = false
	_update_held_orb_position()

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
		clear_speed_boost()

## Applies a temporary paddle speed multiplier (Paddle Boost power-up).
func apply_speed_boost(multiplier: float, duration: float) -> void:
	_speed_boost_multiplier = multiplier
	_speed_boost_time = duration

## Removes any active Paddle Boost. Called on elimination, release, and new round.
func clear_speed_boost() -> void:
	_speed_boost_multiplier = 1.0
	_speed_boost_time = 0.0

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

func _physics_process(delta: float) -> void:
	if held_orb.visible:
		_update_held_orb_position()
	if _speed_boost_time > 0.0:
		_speed_boost_time -= delta
		if _speed_boost_time <= 0.0:
			_speed_boost_multiplier = 1.0
	if not _active or not spawn:
		return
	var input := controller.get_move() if controller else _move_input
	var tangent := _tangent()
	# Joystick input is screen-relative (right = +X, down = +Z). Project it onto
	# this side's tangent so the paddle moves in the direction the player pushes.
	var input_x := input.dot(_tangent_2d())
	var side_half_length := spawn.arena_radius * tan(TAU / 16.0)
	var max_offset := side_half_length * CLAMP_FACTOR
	var offset := (global_position - _side_center()).dot(tangent)
	if (input_x > 0.0 and offset >= max_offset) or (input_x < 0.0 and offset <= -max_offset):
		input_x = 0.0
	velocity = tangent * input_x * MOVE_SPEED * _speed_boost_multiplier
	move_and_slide()

## Shows or hides the visual-only ready orb in front of the paddle.
func set_held_orb_visible(shown: bool) -> void:
	held_orb.visible = shown
	if shown:
		_update_held_orb_position()

## Tints the ready orb with the color of this paddle's player.
func set_held_orb_color(color: Color) -> void:
	var material := held_orb_mesh.material as ShaderMaterial
	if material:
		material.set_shader_parameter("base_color", color)

## World position of the ready orb: in front of the paddle, toward the core.
func held_orb_position() -> Vector3:
	var to_center := Vector3(-global_position.x, 0.0, -global_position.z)
	if to_center.length_squared() < 0.0001:
		to_center = Vector3.FORWARD
	to_center = to_center.normalized()
	return Vector3(
		global_position.x + to_center.x * HELD_ORB_OFFSET,
		GameOrb.ORB_HEIGHT,
		global_position.z + to_center.z * HELD_ORB_OFFSET
	)

func _update_held_orb_position() -> void:
	held_orb.global_position = held_orb_position()

func _tangent() -> Vector3:
	return Vector3(-sin(spawn.base_angle), 0.0, cos(spawn.base_angle))

## Side tangent expressed in screen space, matching DeflectorPlayer's input mapping.
func _tangent_2d() -> Vector2:
	return Vector2(-sin(spawn.base_angle), cos(spawn.base_angle))

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
