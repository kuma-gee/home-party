class_name CountPlayer
extends Node

signal locked_changed(locked: bool)
signal count_changed(count: int)
signal winner_changed(winner: bool)
signal resetted()

var started := false
var time := 0.0
var game_client: GameClient
var is_locked := false:
	set(v):
		is_locked = v
		locked_changed.emit(v)
var count := 0:
	set(v):
		count = v
		game_client.send_text("%s" % count)
		count_changed.emit(v)
var is_winner := false:
	set(v):
		is_winner = v
		winner_changed.emit(v)

func _ready() -> void:
	game_client.input_received.connect(_on_input_received)

func _on_input_received(input: String, value):
	if not started: return
	if input == "action" and value == true and not is_locked:
		count += 1
	elif input == "secondary" and not is_locked:
		is_locked = true

func _process(delta: float) -> void:
	if started and not is_locked:
		time += delta

func reset() -> void:
	count = 0
	time = 0.0
	started = false
	is_locked = false
	is_winner = false
	resetted.emit()

func start():
	started = true

func lock() -> void:
	is_locked = true
