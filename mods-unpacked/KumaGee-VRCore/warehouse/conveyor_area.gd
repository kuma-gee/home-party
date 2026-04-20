extends Area3D

@export var speed := 5
@export var direction: Vector3 = Vector3.FORWARD

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is RigidBody3D:
			body.apply_central_force(direction * speed)
