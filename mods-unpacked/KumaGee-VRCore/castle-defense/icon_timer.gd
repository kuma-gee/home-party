extends Node

@export var timer: Timer

@onready var mat: ShaderMaterial = get_parent().material

func _ready() -> void:
	mat.set_shader_parameter("fill", 1.0)

func _process(_delta: float) -> void:
	if mat == null:
		return
	
	if timer == null or timer.is_stopped():
		mat.set_shader_parameter("fill", 1.0)
	else:
		mat.set_shader_parameter("fill", 1.0 - timer.time_left / timer.wait_time)
