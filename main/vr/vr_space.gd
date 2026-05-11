class_name VRSpace
extends Node

@export var origin: XROrigin3D
@export var camera: XRCamera3D
@export var fade: XRToolsFade

var fade_tw: Tween

# func _ready() -> void:
# 	set_fade(1.0)

# func set_fade(v: float):
# 	fade.set_fade_level(Color(0, 0, 0, v))

# func deactivate(fade_time = 0.5):
# 	if fade_tw:
# 		fade_tw.kill()
# 	fade_tw = create_tween()
# 	fade_tw.tween_method(set_fade, 0.0, 1.0, fade_time)
# 	await fade_tw.finished

func activate():
	# We need another fade here because this will be in a separate viewport, so the fade from staging won't affect it.
	# if fade_tw:
	# 	fade_tw.kill()
	# fade_tw = create_tween()
	# fade_tw.tween_method(set_fade, 1.0, 0.0, fade_time)
	# await fade_tw.finished
	# await get_tree().create_timer(0.1).timeout
	
	origin.current = true
	camera.current = true
