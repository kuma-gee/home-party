class_name GroundSpringCast
extends RayCast3D

signal landed()

@export var spring_strength := 20.0
@export var ride_height := 0.5
@export var damping := 1.0

@export var jump_gravity := 80
@export var gravity = 120 #ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var actual_gravity = gravity

var has_jumped := false
var do_jump := false

func _ready() -> void:
	target_position = target_position.normalized() * ride_height

func _physics_process(delta: float) -> void:
	if not is_colliding():
		do_jump = false
	
	if not is_grounded():
		has_jumped = true
	elif has_jumped:
		actual_gravity = gravity
		landed.emit()

func apply_gravity(player: CharacterBody3D, delta: float):
	if not is_grounded():
		player.velocity.y -= actual_gravity * delta
	else:
		player.velocity.y += apply_spring_force(player.velocity).y

func apply_spring_force(velocity: Vector3) -> Vector3:
	var ray_dir = target_position.normalized()
	var ground_vector = get_collision_point() - global_position
	
	var rel_velocity = ray_dir.dot(velocity)
	var displacement = ground_vector.length() - ride_height
	var force = (displacement * spring_strength) - (rel_velocity * damping)
	
	return ray_dir * force

func is_grounded():
	return is_colliding() and not do_jump

func jump(player: CharacterBody3D, jump_height: float):
	do_jump = true
	player.velocity.y = jump_height
	actual_gravity = jump_gravity
