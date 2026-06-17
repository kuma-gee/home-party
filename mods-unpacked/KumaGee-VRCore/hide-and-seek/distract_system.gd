class_name DistractSystem
extends AudioStreamPlayer3D

## Plays directional 3D audio from the hider's prop position.

@export var distract_sounds: Array[AudioStream] = []


func play_distract(pos: Vector3) -> void:
	if distract_sounds.is_empty():
		return

	stream = distract_sounds.pick_random()
	global_position = pos
	play()
