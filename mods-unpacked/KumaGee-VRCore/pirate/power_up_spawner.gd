class_name PowerUpSpawner
extends Node3D

@export var scene: PackedScene
@export var spawn_timer: RandomTimer
@export var max_count: int = 3
@export var spawn_radius := 6

var enabled := false
var current_count := 0

func _ready() -> void:
	spawn_timer.timeout.connect(_spawn)

func _spawn() -> void:
	if enabled and current_count < max_count:
		var instance = scene.instantiate()
		instance.type = PowerUp.Type.values()[randi() % PowerUp.Type.values().size()]
		instance.position = _random_position()
		instance.tree_exiting.connect(func(): current_count -= 1)
		add_child(instance)
		current_count += 1

func _random_position() -> Vector3:
	var dir = Vector3.FORWARD * randf_range(-spawn_radius, spawn_radius)
	return dir.rotated(Vector3.UP, randf_range(0, TAU))

func start() -> void:
	enabled = true
	spawn_timer.start_random()

func stop() -> void:
	enabled = false
	spawn_timer.stop()
