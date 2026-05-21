extends Node

@export var direction := Vector3.FORWARD
@export var speed := 1.0
@export var node: Node3D

func _physics_process(delta: float) -> void:
	var dir = direction.rotated(Vector3.UP, node.global_rotation.y)
	node.global_position += dir * speed * delta
