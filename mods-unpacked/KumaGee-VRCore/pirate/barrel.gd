class_name Barrel
extends CharacterBody3D

signal picked_up(power_up)

@export var launch_speed: float = 20.0
@export var gravity: float = 6.0
@export var rotation_speed: float = 2.0
@export var high_arc: bool = true
@onready var hit_area: Area3D = $HitArea
@onready var hurt_box: HurtBox = $HurtBox
@onready var free_timer: Timer = $FreeTimer
@onready var break_sfx: RandomizedSfx = $BreakSFX
@onready var power_up_area: HurtBox = $PowerUpArea

var target: Vector3
var active: bool = false
var damage: int = 1
var speed_multiplier: float = 1.0
var rotation_dir: Vector3 = Vector3(1.0, 1.0, 1.0)

func _ready() -> void:
	hit_area.damage = damage
	hit_area.hit.connect(_break)
	hurt_box.died.connect(_break)
	free_timer.timeout.connect(func(): queue_free())
	power_up_area.area_entered.connect(_pick_up_powerup)
	randomize()

func _random_rotation_value():
	return 1.0 if randf() > 0.5 else -1.0

func _break():
	hide()
	active = false
	hit_area.queue_free()
	hurt_box.queue_free()
	free_timer.start()
	break_sfx.start()

	for area in power_up_area.get_overlapping_areas():
		if area is PowerUp:
			_pick_up_powerup(area)

func _pick_up_powerup(power_up: Area3D):
	print("Power up: %s" % power_up)
	if not is_instance_valid(power_up): return
	picked_up.emit(power_up.type)
	power_up.queue_free()

func _physics_process(delta: float) -> void:
	if not active:
		return

	# apply gravity
	velocity += Vector3.DOWN * _get_gravity_scale() * delta

	# rotate while active on all axes
	rotate_x(rotation_speed * rotation_dir.x * delta)
	rotate_y(rotation_speed * rotation_dir.y * delta)
	rotate_z(rotation_speed * rotation_dir.z * delta)

	if move_and_slide():
		_break()

func _get_gravity_scale() -> float:
	return gravity * (1.0 + speed_multiplier/2.0)

func throw_to(target_pos: Vector3) -> void:
	"""Launch the barrel in an arc towards `target_pos` using `speed`.
	If `speed` <= 0 the exported `launch_speed` is used. Uses `high_arc`
	to prefer a higher or lower trajectory when two solutions exist.
	"""
	target = target_pos
	var v = launch_speed * speed_multiplier
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

	var g = _get_gravity_scale()
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
	rotation_dir = Vector3(_random_rotation_value(), _random_rotation_value(), _random_rotation_value())
	active = true
