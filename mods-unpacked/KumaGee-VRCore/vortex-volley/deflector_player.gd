class_name DeflectorPlayer
extends CharacterBody3D

## Player paddle. Movement runs through the CharacterBody3D physics body
## (floating motion mode) alongside the arena ring instead of teleporting
## transform directly. Orb/goal detection runs through the PaddleGoal Area3D.

const MOVE_SPEED: float = 1.8
const FLASH_DURATION: float = 0.2
const CLAMP_FACTOR: float = 0.8
const PADDLE_RADIUS: float = 4.0

var controller: ClientController
var player_name: String = ""
var lives: int = 3
var orb_supply: int = 1
var base_angle: float = 0.0
var arena_radius: float = 4.5

@onready var paddle_material: StandardMaterial3D = $Visual.material_override
@onready var _goal_area: Area3D = $PaddleGoal
@onready var static_body_3d: StaticBody3D = $StaticBody3D
@onready var visual: MeshInstance3D = $Visual

var _move_input: Vector2 = Vector2.ZERO
var _game_manager: VortexArena
var _eliminated: bool = false
var _color: Color = Color.WHITE

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_goal_area.body_entered.connect(_on_goal_body_entered)

## Reassigns this paddle to a player (or releases it when both args are null).
## Pre-placed paddles are reused across rounds, so signal wiring follows the controller.
func set_controller(player: ClientController, manager: VortexArena) -> void:
	if controller == player and _game_manager == manager:
		return
	_disconnect_controller_signals()
	controller = player
	_game_manager = manager
	if controller:
		_connect_controller_signals()
		_set_blocker(false)

func apply_player_color() -> void:
	if not controller or not paddle_material:
		return
	var idx := PlayerManager.get_player_idx(controller.uuid)
	_color = PlayerList.get_color(idx) if idx >= 0 else Color.WHITE
	paddle_material.albedo_color = _color
	paddle_material.emission = _color
	paddle_material.emission_energy_multiplier = 0.6

## Hides the paddle and disables gameplay without touching its controller state.
## The static blocker takes over the slot so the ball bounces off instead of
## passing through an empty sector.
func deactivate() -> void:
	visible = false
	collision_layer = 0
	_set_blocker(true)
	if _goal_area:
		_goal_area.monitoring = false
	if paddle_material:
		paddle_material.emission_energy_multiplier = 0.6

## Enables/disables the slot's static blocker. The blocker is active whenever
## no player is placed here; a controlled paddle must never be blocked solid.
func _set_blocker(enabled: bool) -> void:
	if not static_body_3d:
		return
	static_body_3d.collision_layer = 1 if enabled else 0
	static_body_3d.collision_mask = 1 if enabled else 0
	static_body_3d.visible = enabled

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
	if _eliminated:
		return
	var input := controller.get_move() if controller else _move_input
	var tangent := _tangent()
	var side_half_length := arena_radius * tan(TAU / 16.0)
	var max_offset := side_half_length * CLAMP_FACTOR
	var offset := (global_position - _side_center()).dot(tangent)
	if (input.x > 0.0 and offset >= max_offset) or (input.x < 0.0 and offset <= -max_offset):
		input.x = 0.0
	velocity = tangent * input.x * MOVE_SPEED
	move_and_slide()

func _tangent() -> Vector3:
	return Vector3(-sin(base_angle), 0.0, cos(base_angle))

func _side_center() -> Vector3:
	return Vector3(
		cos(base_angle) * PADDLE_RADIUS,
		GameOrb.ORB_HEIGHT,
		sin(base_angle) * PADDLE_RADIUS
	)

func _on_goal_body_entered(body: Node3D) -> void:
	if body is GameOrb and _game_manager:
		_game_manager.on_orb_passed(self, body)

func flash_hit() -> void:
	if not paddle_material:
		return
	paddle_material.emission = Color(1.0, 0.0, 0.0)
	paddle_material.emission_energy_multiplier = 3.0
	var tw := create_tween()
	tw.tween_property(paddle_material, "emission_energy_multiplier", 0.6, FLASH_DURATION)
	tw.tween_property(paddle_material, "emission", _color, 0.0)

func eliminate() -> void:
	_eliminated = true
	visible = false
	collision_layer = 0
	if _goal_area:
		_goal_area.monitoring = false

func revive() -> void:
	_eliminated = false
	visible = true
	collision_layer = 1
	_set_blocker(false)
	if _goal_area:
		_goal_area.monitoring = true

func set_orb_ready() -> void:
	if not paddle_material or _eliminated:
		return
	paddle_material.emission_energy_multiplier = 1.2

func _on_moved(dir: Vector2) -> void:
	_move_input = dir

func _on_launch() -> void:
	if _eliminated or orb_supply <= 0:
		return
	if _game_manager:
		_game_manager.request_launch(self)
