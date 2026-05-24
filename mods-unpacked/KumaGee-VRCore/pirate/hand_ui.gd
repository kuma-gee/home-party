extends Sprite3D

@export var palm_up_threshold := 9.0

func _process(_delta: float) -> void:
	var palm_direction = global_basis.x.normalized()
	visible = palm_direction.dot(Vector3.UP) > 0.8
