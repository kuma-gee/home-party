extends Node

@export var timer: Timer

func _process(_delta: float) -> void:
	var mat := get_parent().material as ShaderMaterial
	if mat == null:
		return
	if timer == null or timer.is_stopped():
		mat.set_shader_parameter("fill", 1.0)
	else:
		mat.set_shader_parameter("fill", 1.0 - timer.time_left / timer.wait_time)
