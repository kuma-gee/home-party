extends Area3D

@export var max_pull_force: float = 100.0
@export var pull_exponent: float = 5.0
@export var exponential_pull: bool = true
@export var enabled := true
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var pull_radius: float = 0.0

func _ready() -> void:
	var sphere = collision_shape_3d.shape as SphereShape3D
	pull_radius = sphere.radius

func _physics_process(delta: float) -> void:
	if not enabled: return
	
	for body in get_overlapping_bodies():
		if not body is CharacterBody3D:
			continue

		var to_center: Vector3 = global_position - body.global_position
		var distance: float = to_center.length()
		if distance == 0.0:
			continue

		var t: float = 1.0 - clampf(distance / pull_radius, 0.0, 1.0)
		var strength: float = max_pull_force * (pow(t, pull_exponent) if exponential_pull else t)
		body.velocity += to_center.normalized() * strength * delta
