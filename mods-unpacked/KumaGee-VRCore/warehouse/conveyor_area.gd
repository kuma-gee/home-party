extends Area3D

@export var speed := 5
@export var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_exited.connect(_on_body_exited)

func _on_body_exited(body: Node) -> void:
	if body is RigidBody3D:
		body.linear_velocity = Vector3.ZERO

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is RigidBody3D:
			body.linear_velocity = direction * speed
