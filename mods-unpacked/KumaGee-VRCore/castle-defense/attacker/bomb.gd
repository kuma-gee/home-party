@tool
class_name Bomb
extends XRToolsPickable

signal exploded()

@export var base_damage := 3
@export var firepower_label: Label
@export var power_sprite: Sprite3D

@onready var explode_trigger: Area3D = $ExplodeTrigger
@onready var hit_box: HitBox = $HitBox
@onready var lighting_fuse: AudioStreamPlayer = $LightingFuse

var firepower := 1:
	set(v):
		firepower = v
		firepower_label.text = "%d" % firepower

func _ready():
	explode_trigger.area_entered.connect(func(_a): explode())
	picked_up.connect(func(_p):
		lighting_fuse.play()
		power_sprite.show()
	)
	dropped.connect(func(_p): queue_free())
	power_sprite.hide()

func explode() -> void:
	exploded.emit()
	hit_box.hit(base_damage * firepower)
	queue_free()
