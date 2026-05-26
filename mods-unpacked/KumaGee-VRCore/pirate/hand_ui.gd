extends Sprite3D

@export var palm_up_threshold := 0.8

func _process(_delta: float) -> void:
	if get_tree().paused:
		hide()
		return
	
	var palm_direction = global_basis.x.normalized()
	visible = palm_direction.dot(Vector3.UP) > palm_up_threshold
