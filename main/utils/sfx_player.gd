class_name SFXPlayer
extends Node

@export var audio: AudioStream
@export var min_pitch := 1.0
@export var max_pitch := -1.0
@export var volume := -15.0
@export var play_on_ready := false

func _ready() -> void:
	if play_on_ready:
		play()
	
func play():
	var p = randf_range(min_pitch, max(max_pitch, min_pitch))
	AudioManager.play_sfx(audio, volume, p)
