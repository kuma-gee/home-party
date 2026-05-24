@tool
class_name RandomizedSfx
extends AudioStreamPlayer3D

const GROUP = "AudioSFX"

@export var id := ""
@export var max_plays := 4
@export var min_pitch := 0.8
@export var max_pitch := 1.0
@export var one_shot := true

var active := false

func _ready() -> void:
	if id:
		add_to_group(get_group())

	if one_shot:
		finished.connect(func(): active = false)
	else:
		finished.connect(func():
			if active:
				play_randomized()
			)

func get_group():
	return GROUP + "_" + id

func start():
	active = true
	play_randomized()

func end():
	active = false

func play_randomized():
	if id != "":
		var count = _count_same_audio_plays()
		if count >= max_plays:
			return

	pitch_scale = randf_range(min_pitch, max_pitch)
	play()

func _count_same_audio_plays() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(get_group()):
		if node is AudioStreamPlayer and node.playing:
			count += 1
	return count
