class_name VRSpace
extends Node

@export var origin: XROrigin3D
@export var camera: XRCamera3D
@export var fade: XRToolsFade

var fade_tw: Tween

func _ready() -> void:
	set_fade(1.0)

func set_fade(v: float):
	fade.set_fade_level("", Color(0, 0, 0, v))

func deactivate():
	if fade_tw:
		fade_tw.kill()
	fade_tw = create_tween()
	fade_tw.tween_method(set_fade, 0.0, 1.0, 0.5)
	await fade_tw.finished

func activate():
	if fade_tw:
		fade_tw.kill()
	fade_tw = create_tween()
	fade_tw.tween_method(set_fade, 1.0, 0.0, 0.5)
	await fade_tw.finished
	await get_tree().create_timer(0.2).timeout
	
	origin.current = true
	camera.current = true
