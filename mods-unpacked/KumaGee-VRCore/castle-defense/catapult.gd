class_name Catapult
extends Node3D

enum State { EMPTY, LOADED }

@export var gate_target: Node3D
@export var boulder_scene: PackedScene

var state := State.EMPTY
var _players_in_zone: Dictionary = {}

@onready var operating_zone: Area3D = $OperatingZone
@onready var cooldown: Timer = $Cooldown
@onready var arm: Node3D = $Arm

func _ready() -> void:
	cooldown.wait_time = 5.0
	cooldown.one_shot = true
	operating_zone.body_entered.connect(_on_body_entered)
	operating_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not body is FPSPlayer:
		return
	var player := body as FPSPlayer
	var callable := func(input: String, value: Variant): _on_player_input(input, value, player)
	_players_in_zone[player] = callable
	player.game_client.input_received.connect(callable)

func _on_body_exited(body: Node3D) -> void:
	if not body is FPSPlayer:
		return
	var player := body as FPSPlayer
	if player in _players_in_zone:
		player.game_client.input_received.disconnect(_players_in_zone[player])
		_players_in_zone.erase(player)

func _on_player_input(input: String, value: Variant, _player: FPSPlayer) -> void:
	if input != "action" or value != true:
		return
	if not cooldown.is_stopped():
		return
	match state:
		State.EMPTY:
			state = State.LOADED
			_set_arm_loaded(true)
		State.LOADED:
			_fire()
			state = State.EMPTY
			_set_arm_loaded(false)
			cooldown.start()

func _fire() -> void:
	if not boulder_scene or not gate_target:
		return
	var launch_pos = $Arm/LaunchPoint.global_position if has_node("Arm/LaunchPoint") else global_position + Vector3.UP * 2.0
	var boulder := boulder_scene.instantiate()
	boulder.position = launch_pos
	get_tree().current_scene.add_child(boulder)
	boulder.global_position = launch_pos
	boulder.throw_to(gate_target.global_position + Vector3.UP * 2.5)

func _set_arm_loaded(loaded: bool) -> void:
	if is_instance_valid(arm):
		arm.rotation_degrees.x = -80.0 if loaded else 0.0
