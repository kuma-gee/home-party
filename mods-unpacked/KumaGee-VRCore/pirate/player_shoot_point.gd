class_name PlayerShootPoint
extends Node3D

signal shoot_at(target: Vector3)

@export var move_speed := 0.05
@export var move_radius := 5.0
@export var visuals: Node3D
@export var fire_rate := 2.0

# global target position
var current_target: Vector3 = Vector3.ZERO:
	set(v):
		current_target = v
		visuals.global_transform.origin = v

var direction := Vector3.ZERO
var game_client: GameClient
var last_shot_time := 0.0

func _ready() -> void:
	current_target = Vector3.ZERO
	game_client.input_received.connect(_input_received)

func _input_received(action: String, value):
	if action == "move":
		_move(value)
	elif action == "action" and value == true:
		_shoot()
	
func _move(value: Vector2) -> void:
	direction = Vector3(value.x, 0, value.y)

func _process(_delta: float) -> void:
	if direction.length() < 0.01:
		return

	var center_pos = Vector3.ZERO
	var new_pos = current_target + direction * move_speed
	new_pos.y = center_pos.y

	var offset = new_pos - center_pos
	var dist = offset.length()
	if dist > move_radius:
		offset = offset.normalized() * move_radius
		new_pos = center_pos + offset

	current_target = new_pos
	
func _shoot():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_shot_time >= 1.0 / fire_rate:
		shoot_at.emit(current_target)
		last_shot_time = current_time
