class_name Barrel
extends CharacterBody3D

@export var launch_speed: float = 10.0
@export var gravity: float = 7.0
@export var high_arc: bool = true
@onready var hit_area: Area3D = $HitArea
@onready var hurt_box: HurtBox = $HurtBox

var target: Vector3
var active: bool = false
var proj_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	hit_area.hit.connect(_break)
	hurt_box.died.connect(_break)

func _break():
	queue_free()

func _physics_process(delta: float) -> void:
	if not active:
		return

	velocity += Vector3.DOWN * gravity * delta
	if move_and_slide():
		queue_free()


func throw_to(target_pos: Vector3, speed: float = -1.0) -> void:
	"""Launch the barrel in an arc towards `target_pos` using `speed`.
	If `speed` <= 0 the exported `launch_speed` is used. Uses `high_arc`
	to prefer a higher or lower trajectory when two solutions exist.
	"""
	target = target_pos
	var v = speed if speed > 0.0 else launch_speed
	var origin = global_transform.origin
	var to_target = target - origin
	var horizontal = Vector3(to_target.x, 0.0, to_target.z)
	var h = horizontal.length()
	var dy = to_target.y

	if h < 0.001:
		# Mostly vertical shot
		velocity = Vector3.UP * v
		active = true
		return

	var g = gravity
	var v2 = v * v
	var under = v2 * v2 - g * (g * h * h + 2.0 * dy * v2)

	if under < 0.0:
		# Cannot reach target at given speed: aim directly at it with given speed
		velocity = to_target.normalized() * v
		active = true
		return

	var sqrtv = sqrt(under)
	var tan_theta = 0.0
	if high_arc:
		tan_theta = (v2 + sqrtv) / (g * h)
	else:
		tan_theta = (v2 - sqrtv) / (g * h)

	var theta = atan(tan_theta)
	var vxz = v * cos(theta)
	var vy = v * sin(theta)
	var hor_dir = horizontal.normalized()

	velocity = hor_dir * vxz + Vector3.UP * vy
	active = true
