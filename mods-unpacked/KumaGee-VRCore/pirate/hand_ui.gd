extends Sprite3D

@export var palm_up_threshold := 0.5

func _process(_delta: float) -> void:
	var palm_direction = global_basis.x
	visible = palm_direction.dot(Vector3.UP) > palm_up_threshold
