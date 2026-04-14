extends Node

const MAX_AUDIO_PLAYERS = 16

var _audio_players: Array[AudioStreamPlayer] = []
var _available_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in MAX_AUDIO_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		player.finished.connect(_on_player_finished.bind(player))
		_audio_players.append(player)
		_available_players.append(player)

func play_randomized_sfx(stream: AudioStream, volume: float, min_pitch = 0.8, max_pitch = 1.2):
	play_sfx(stream, volume, randf_range(min_pitch, max_pitch))

func play_sfx(stream: AudioStream, volume_db: float = -10.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	
	var player = _get_available_player()
	if not player:
		push_warning("No available audio players")
		return
	
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _get_available_player() -> AudioStreamPlayer:
	if _available_players.is_empty():
		return null
	
	var player = _available_players.pop_front()
	return player

func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player not in _available_players:
		_available_players.append(player)
