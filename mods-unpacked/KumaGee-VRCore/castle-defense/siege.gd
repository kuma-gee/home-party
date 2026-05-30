extends Node3D
class_name Siege

@export var target_pos: Node3D
@export var launch_pos: Node3D
@export var spread_radius: float = 5.0
@onready var meteorite_launcher: MeteoriteLauncher = $MeteoriteLauncher
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start():
	animation_player.play("start")

func fire():
	var random_offset = Vector3(
		randf_range(-spread_radius, spread_radius),
		0,
		randf_range(-spread_radius, spread_radius)
	)
	# Clamp offset to circle
	if random_offset.length() > spread_radius:
		random_offset = random_offset.normalized() * spread_radius
	
	var target = target_pos.global_position + random_offset
	meteorite_launcher.launch(launch_pos.global_position, target)
