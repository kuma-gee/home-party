class_name SpawnHint
extends Control

@onready var _timer: Timer = $Timer

var started := false

func _ready() -> void:
	hide()

func start(player_list: PlayerList) -> void:
	show()
	for child in player_list.get_children():
		if child is CastlePlayerUI:
			child.player_spawned.connect(_on_player_spawned, CONNECT_ONE_SHOT)

func _on_player_spawned() -> void:
	if started: return
	started = true
	_timer.start()

func _on_timer_timeout() -> void:
	hide()
