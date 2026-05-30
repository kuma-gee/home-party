extends Node3D
class_name MeteoriteLauncher

@export var meteorite_scene: PackedScene = preload("res://mods-unpacked/KumaGee-VRCore/castle-defense/vfx/meteorite_vfx.tscn")
@export var min_count: int = 2
@export var max_count: int = 3
@export var delay_min: float = 0.15
@export var delay_max: float = 0.4

func launch(start_pos: Vector3, target_pos: Vector3, arc_height: float = 10.0, gravity: float = 20.0) -> void:
	var count = randi_range(min_count, max_count)
	for i in count:
		if i > 0:
			await get_tree().create_timer(randf_range(delay_min, delay_max)).timeout
		_spawn_meteorite(start_pos, target_pos, arc_height, gravity)

func _spawn_meteorite(start_pos: Vector3, target_pos: Vector3, arc_height: float, gravity: float) -> void:
	var meteorite = meteorite_scene.instantiate() as CharacterBody3D
	meteorite.position = start_pos
	meteorite.gravity = gravity
	
	var direction = target_pos - start_pos
	var horizontal_dist = Vector2(direction.x, direction.z).length()
	var time_to_target = sqrt(2.0 * arc_height / gravity) + sqrt(2.0 * (arc_height + abs(direction.y)) / gravity)
	
	if time_to_target > 0.001:
		var velocity_xz = Vector3(direction.x, 0, direction.z) / time_to_target
		var velocity_y = sqrt(2.0 * gravity * arc_height)
		if direction.y > 0:
			velocity_y = sqrt(2.0 * gravity * (arc_height + direction.y))
		meteorite.velocity = Vector3(velocity_xz.x, velocity_y, velocity_xz.z)
	
	Staging.add_scene_child(meteorite)
