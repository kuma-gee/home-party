class_name Boulder
extends CharacterBody3D

@export var base_damage: int = 1
@export var launch_speed: float = 18.0
@export var gravity: float = 12.0
@export var high_arc: bool = false
@export var hit_vfx: PackedScene

@onready var hit_area: Area3D = $HitArea
@onready var free_timer: Timer = $FreeTimer

var power := 0
var active := false
	
func _ready() -> void:
	hit_area.area_entered.connect(_on_hit_area_area_entered)
	free_timer.one_shot = true
	free_timer.timeout.connect(queue_free)

func on_hit():
	queue_free()

func _on_hit_area_area_entered(area: Area3D) -> void:
	if not active:
		return
	if area is HurtBox:
		area.hit(base_damage * power)
		_break()

func _break() -> void:
	if not active:
		return
	active = false
	if hit_vfx:
		var vfx = hit_vfx.instantiate()
		vfx.position = global_position
		Staging.add_scene_child(vfx)
	hide()
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	free_timer.start(0.5)

func _physics_process(delta: float) -> void:
	if not active:
		return
	velocity += Vector3.DOWN * gravity * delta
	if move_and_slide():
		_break()

func throw_to(target_pos: Vector3) -> void:
	var v := launch_speed
	var origin := global_transform.origin
	var to_target := target_pos - origin
	var horizontal := Vector3(to_target.x, 0.0, to_target.z)
	var h := horizontal.length()
	var dy := to_target.y

	if h < 0.001:
		velocity = Vector3.UP * v
		active = true
		return

	var g := gravity
	var v2 := v * v
	var under := v2 * v2 - g * (g * h * h + 2.0 * dy * v2)

	if under < 0.0:
		velocity = to_target.normalized() * v
		active = true
		return

	var sqrtv := sqrt(under)
	var tan_theta := (v2 - sqrtv) / (g * h) if not high_arc else (v2 + sqrtv) / (g * h)
	var theta := atan(tan_theta)
	var vxz := v * cos(theta)
	var vy := v * sin(theta)
	var hor_dir := horizontal.normalized()

	velocity = hor_dir * vxz + Vector3.UP * vy
	active = true
