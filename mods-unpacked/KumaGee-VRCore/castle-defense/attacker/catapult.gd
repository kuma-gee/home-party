class_name Catapult
extends Node3D

enum State { EMPTY, LOADED }

@export var gate_target: Node3D
@export var boulder_scene: PackedScene
@export var charge_time := 5.0
@export var charge_speed := 8.0
@export var launch_speed := 40.0
@export var decharge_speed := 0.7
@export var boulder_spawn: Node3D
@export var catapult_arm: Node3D
@export var catapult_start_rot := -60.0

@onready var operating_zone: Area3D = $OperatingZone
@onready var cooldown_timer: Timer = $CooldownTimer

var charge := 0.0:
	set(v):
		charge = clamp(v, 0.0, charge_time)
		_set_arm_load(charge / charge_time)

func _ready() -> void:
	charge = 0.0

func get_player_count():
	return operating_zone.get_overlapping_areas().size()

func _process(delta: float) -> void:
	var player_count = get_player_count()
	if player_count > 0 and cooldown_timer.is_stopped():
		print("Player count %s" % player_count)
		if charge < charge_time:
			charge += delta * log(player_count * charge_speed) / log(10)
		else:
			_fire()
	elif charge > 0.0:
		var t := charge / charge_time
		var speed_factor = lerp(0.3, 1.0, t)
		var speed = decharge_speed if cooldown_timer.is_stopped() else launch_speed
		charge -= delta * speed * speed_factor
		# if cooldown timer is running, preserve current charge until cooldown ends


func _fire() -> void:
	if not boulder_scene or not gate_target:
		return
	
	cooldown_timer.start()
	var launch_pos = boulder_spawn.global_position
	var boulder := boulder_scene.instantiate()
	boulder.position = launch_pos
	get_tree().current_scene.add_child(boulder)
	boulder.throw_to(gate_target.global_position + Vector3.UP)

func _set_arm_load(p: float) -> void:
	catapult_arm.rotation_degrees.z = lerp(catapult_start_rot, 0.0, p)
