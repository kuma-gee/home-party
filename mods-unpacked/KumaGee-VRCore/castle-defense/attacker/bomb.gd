@tool
class_name Bomb
extends XRToolsPickable

signal exploded()

@export var base_damage := 1
@export var firepower_label: Label
@export var power_sprite: Sprite3D
@export var explode_timer: Timer
@export var fire_vfx: Node3D

@onready var explode_trigger: Area3D = $ExplodeTrigger
@onready var hit_box: HitBox = $HitBox
@onready var lighting_fuse: AudioStreamPlayer = $LightingFuse
@onready var explosion_hit_trigger: Area3D = $ExplosionHitTrigger

var has_exploded := false
var firepower := 1:
	set(v):
		firepower = v
		firepower_label.text = "%d" % firepower

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

func explode(reached = false) -> void:
	if has_exploded: return
	has_exploded = true
	
	exploded.emit()
	if reached:
		for body in explosion_hit_trigger.get_overlapping_bodies():
			if body.has_method("trigger_explosion"):
				body.trigger_explosion()
	
	hit_box.hit(base_damage * firepower)
	queue_free()

func trigger_explosion():
	explode()
