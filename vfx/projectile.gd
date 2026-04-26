extends RigidBody3D

@export var speed: float = 10.0
@export var hit_box: HitBox
@export var delay_trails_start: float = 0.2
@export var hit_effect: PackedScene

var trails = []
#var resource: ProjectileResource:
	#set(v):
		#resource = v
		#speed = resource.speed
		#hit_box.damage = resource.damage

func _ready() -> void:
	hit_box.area_entered.connect(func(_a): _on_hit())
	
	for child in get_children():
		if child is GPUTrail3D:
			trails.append(child)

func _physics_process(_delta: float) -> void:
	linear_velocity = -global_transform.basis.z * speed

	if not get_colliding_bodies().is_empty():
		_on_hit()

func _on_hit():
	hit_box.hit()
	
	var effect = hit_effect.instantiate()
	effect.position = global_position
	get_tree().current_scene.add_child(effect)

	queue_free()

func delay_trails():
	if trails.is_empty():
		return
	
	for trail in trails:
		if is_instance_valid(trail):
			trail.speed_scale = 0  # Stop movement initially, avoids glitches

	await get_tree().create_timer(delay_trails_start).timeout

	for trail in trails:
		if is_instance_valid(trail):
			trail.speed_scale = 1  # Resume movement
