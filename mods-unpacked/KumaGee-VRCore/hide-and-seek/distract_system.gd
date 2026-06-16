class_name DistractSystem
extends Node

## Handles distract sounds for mobile hiders.
## Plays directional 3D audio from the hider's prop position.

## Distract sounds (assign in editor or use generated tones)
@export var distract_sounds: Array[AudioStream] = []

## Sound volume
@export var volume_db: float = 0.0

## Preloaded sound players (pooled)
var _sound_pool: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	# Create a pool of sound players
	for i in 3:  # Pool of 3 for overlapping sounds
		var player = AudioStreamPlayer3D.new()
		player.volume_db = volume_db
		player.attenuation = 0.0  # No attenuation - full volume at any distance
		player.max_distance = 100.0
		add_child(player)
		_sound_pool.append(player)

func play_distract(position: Vector3) -> void:
	"""Play a random distract sound at the given position."""
	if distract_sounds.is_empty():
		# Use a generated tone as fallback
		_play_tone(position)
		return
	
	# Pick a random sound
	var sound = distract_sounds.pick_random()
	
	# Get an available player from the pool
	var player = _get_available_player()
	if not player:
		return
	
	player.stream = sound
	player.global_position = position
	player.play()

func _play_tone(position: Vector3) -> void:
	"""Play a generated tone as fallback when no sounds are assigned."""
	var player = _get_available_player()
	if not player:
		return
	
	# Generate a simple tone using AudioStreamGenerator
	var generator = AudioStreamGenerator.new()
	generator.buffer_size = 44100  # 1 second at 44.1kHz
	generator.mix_rate = 44100
	
	player.stream = generator
	player.global_position = position
	player.play()

func _get_available_player() -> AudioStreamPlayer3D:
	"""Get an available sound player from the pool."""
	for player in _sound_pool:
		if not player.playing:
			return player
	# All players busy, reuse the first one
	return _sound_pool[0]
