extends Node3D

@export var package_scene: PackedScene
@export var timer: Timer

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	var package_instance = package_scene.instantiate()
	add_child(package_instance)
	package_instance.global_transform.origin = global_transform.origin
