class_name PlayerShootPoint
extends Node3D

signal shoot_at(target: Vector3)

@export var move_speed := 0.05
@export var move_radius := 7.0
@export var visuals: Node3D
@export var fire_rate := 1.0

# global target position
var current_target: Vector3 = Vector3.ZERO:
	set(v):
		current_target = v
		visuals.global_transform.origin = v

var direction := Vector3.ZERO
var game_client: GameClient
var last_shot_time := 0.0

var powerups := {
	PowerUp.Type.FIRERATE: 0,
	PowerUp.Type.SIZE: 0,
	PowerUp.Type.SPEED: 0,
}

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

	var new_pos = current_target + direction * move_speed
	new_pos.y = 0
	current_target = new_pos.limit_length(move_radius)
	
func _shoot():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_shot_time >= 1.0 / (fire_rate * get_firerate_multiplier()):
		shoot_at.emit(current_target)
		last_shot_time = current_time

func add_power_up(power_up_type):
	powerups[power_up_type] += 1
	powerups[power_up_type] = min(powerups[power_up_type], 3)
	print("Power-up added: ", power_up_type, " Total: ", powerups[power_up_type])

func get_firerate_multiplier() -> float:
	var multiplier = 1.0
	if powerups[PowerUp.Type.FIRERATE] > 0:
		multiplier += 0.1 * powerups[PowerUp.Type.FIRERATE]
	return multiplier

func get_speed_multiplier() -> float:
	var multiplier = 1.0
	if powerups[PowerUp.Type.SPEED] > 0:
		multiplier += 0.5 * powerups[PowerUp.Type.SPEED]
	return multiplier

func get_scale_multiplier() -> float:
	var s = 1.0
	if powerups[PowerUp.Type.SIZE] > 0:
		s += 0.2 * powerups[PowerUp.Type.SIZE]
	return s
