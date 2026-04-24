class_name Bomb
extends XRToolsPickable

@export var damage := 5

signal exploded

func explode() -> void:
	exploded.emit()
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hide()
	queue_free()
