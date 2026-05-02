@tool
class_name Bomb
extends XRToolsPickable

@export var damage := 5
@onready var explode_trigger: Area3D = $ExplodeTrigger
@onready var hit_box: HitBox = $HitBox
@onready var lighting_fuse: AudioStreamPlayer = $LightingFuse
@onready var hurt_box: HurtBox = $HurtBox

func _ready():
	explode_trigger.area_entered.connect(func(_a): explode())
	picked_up.connect(func(_p): lighting_fuse.play())
	hurt_box.died.connect(func(): queue_free())

func explode() -> void:
	hit_box.hit()
	queue_free()
