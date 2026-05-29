@tool
class_name Bomb
extends XRToolsPickable

signal exploded()

@export var base_damage := 1
@export var firepower_label: Label
@export var power_sprite: Sprite3D
@export var explode_timer: Timer
@export var fire_vfx: Node3D
@export var explosion_vfx: PackedScene

@export_category("Pulse")
@export var pulse_speed_min := 3.0
@export var pulse_speed_max := 18.0
@export var pulse_amplitude_min := 0.15
@export var pulse_amplitude_max := 0.3
@export var color_flash_threshold := 0.7

@onready var explode_trigger: Area3D = $ExplodeTrigger
@onready var hit_box: HitBox = $HitBox
@onready var lighting_fuse: AudioStreamPlayer = $LightingFuse
@onready var explosion_hit_trigger: Area3D = $ExplosionHitTrigger

var has_exploded := false
var firepower := 1:
	set(v):
		firepower = v
		firepower_label.text = "%d🔥" % firepower

var _pulse_time := 0.0

func _ready():
	explode_trigger.area_entered.connect(func(_a): explode(true))
	picked_up.connect(func(_p):
		lighting_fuse.play()
		power_sprite.show()
		fire_vfx.show()
		if explode_timer:
			explode_timer.start()
	)
	explode_timer.timeout.connect(func(): explode())
	dropped.connect(func(_p): queue_free())
	power_sprite.hide()
	fire_vfx.hide()

func _process(delta: float) -> void:
	if not firepower_label or not explode_timer:
		return
	if explode_timer.is_stopped() or has_exploded:
		_pulse_time = 0.0
		firepower_label.scale = Vector2.ONE
		firepower_label.pivot_offset = firepower_label.size / 2.0
		firepower_label.modulate = Color.WHITE
		return

	_pulse_time += delta

	var progress := 1.0 - (explode_timer.time_left / explode_timer.wait_time)
	var speed := lerpf(pulse_speed_min, pulse_speed_max, progress)
	var amplitude := lerpf(pulse_amplitude_min, pulse_amplitude_max, progress)
	var s := 1.0 + amplitude * sin(_pulse_time * speed)
	firepower_label.pivot_offset = firepower_label.size / 2.0
	firepower_label.scale = Vector2.ONE * s

	if progress > color_flash_threshold:
		var flash := (sin(_pulse_time * speed) + 1.0) / 2.0
		var flash_progress := (progress - color_flash_threshold) / (1.0 - color_flash_threshold)
		firepower_label.modulate = Color.WHITE.lerp(Color.RED, flash * flash_progress)
	else:
		firepower_label.modulate = Color.WHITE

func explode(reached = false) -> void:
	if has_exploded: return
	has_exploded = true
	Staging.create_sfx_at(explosion_vfx, global_position)

	exploded.emit()
	if reached:
		for body in explosion_hit_trigger.get_overlapping_bodies():
			if body.has_method("trigger_explosion"):
				body.trigger_explosion()

	hit_box.hit(base_damage * firepower)
	queue_free()

func trigger_explosion():
	explode()
