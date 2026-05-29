extends Node

var volume_db := -25.0
var fade_out_volume_db := -60.0
var fade_time := 1.0

var _player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func start(stream: AudioStream) -> void:
	if not stream:
		return
	_player.volume_db = fade_out_volume_db
	_player.stream = stream
	_player.play()
	_fade_to(volume_db)

func stop() -> void:
	if not _player.playing:
		return
	_fade_to(fade_out_volume_db)
	_tween.finished.connect(func(): _player.stop(), CONNECT_ONE_SHOT)

func set_volume_db(target_db: float, immediate: bool = true) -> void:
	if immediate:
		if _tween:
			_tween.kill()
		_player.volume_db = target_db
	else:
		_fade_to(target_db)

func _fade_to(target_db: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", target_db, fade_time)
