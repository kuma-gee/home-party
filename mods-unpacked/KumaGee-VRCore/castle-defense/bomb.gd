@tool
class_name Bomb
extends XRToolsPickable

@export var damage := 5
@onready var explode_trigger: Area3D = $ExplodeTrigger
@onready var hit_box: HitBox = $HitBox

func _ready():
	explode_trigger.area_entered.connect(func(_a): explode())

func explode() -> void:
	hit_box.hit()
	queue_free()
