extends ColorRect

@export var timer: Timer

func _process(_delta: float) -> void:
	if timer.is_stopped():
		set_fill(0.0)
		hide()
	else:
		var v = timer.time_left / timer.wait_time
		set_fill(v)
		show()

func set_fill(v: float):
	var mat = material as ShaderMaterial
	mat.set_shader_parameter("fill", v)
