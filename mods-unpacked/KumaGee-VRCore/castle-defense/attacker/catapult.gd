class_name Catapult
extends Node3D

enum State { EMPTY, LOADED }

@export var gate_target: Node3D
@export var boulder_scene: PackedScene
@export var charge_time := 5.0
@export var charge_speed := 10.0
@export var launch_speed := 40.0
@export var decharge_speed := 0.8
@export var boulder_spawn: Node3D
@export var catapult_arm: Node3D
@export var catapult_start_rot := -60.0

@export var power_label: Label
@export var power_sprite: Sprite3D

@onready var operating_zone: Area3D = $OperatingZone
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var _player_area: Sprite3D = $PlayerArea

var _prepare_mode := false
var _fade_tween: Tween

var charge := 0.0:
	set(v):
		charge = clamp(v, 0.0, charge_time)
		_set_arm_load(charge / charge_time)
	
var power := 0:
	set(v):
		power = v
		power_label.text = "%d🔥" % power
		power_sprite.visible = power > 0

func _ready() -> void:
	charge = 0.0

func set_prepare_mode(v: bool) -> void:
	if _fade_tween:
		_fade_tween.kill()
		_fade_tween = null
	_prepare_mode = v
	process_mode = Node.PROCESS_MODE_ALWAYS if v else Node.PROCESS_MODE_INHERIT
	if not v:
		if is_instance_valid(_player_area):
			_fade_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			_fade_tween.tween_property(_player_area, "scale", Vector3.ONE, 0.5)
			_fade_tween.parallel().tween_property(_player_area, "modulate", Color(1, 1, 1, 0.05), 0.5)
	else:
		_player_area.modulate = Color(1, 1, 1, 0.05)

func get_total_power():
	var total = 0
	for body in operating_zone.get_overlapping_bodies():
		if body is FPSPlayer:
			var player = body as FPSPlayer
			total += player.firepower
	return total

func _process(delta: float) -> void:
	power = get_total_power()

	if _prepare_mode:
		var t := sin(Time.get_ticks_msec() * 0.003) * 0.5 + 0.5
		var s := lerpf(1.0, 1.3, t)
		_player_area.scale = Vector3.ONE * s

	if power > 0 and cooldown_timer.is_stopped():
		var player_count = operating_zone.get_overlapping_bodies().size()
		if charge < charge_time:
			charge += delta * log(player_count * charge_speed) / log(10)
		else:
			_fire()
	elif charge > 0.0:
		var t := charge / charge_time
		var speed_factor = lerp(0.3, 1.0, t)
		var speed = decharge_speed if cooldown_timer.is_stopped() else launch_speed
		charge -= delta * speed * speed_factor


func _fire() -> void:
	if not boulder_scene or not gate_target:
		return
	
	cooldown_timer.start()
	var launch_pos = boulder_spawn.global_position
	var boulder := boulder_scene.instantiate()
	boulder.position = launch_pos
	boulder.power = power
	Staging.add_scene_child(boulder)
	boulder.throw_to(gate_target.global_position + Vector3.UP)

func _set_arm_load(p: float) -> void:
	catapult_arm.rotation_degrees.z = lerp(catapult_start_rot, 0.0, p)
