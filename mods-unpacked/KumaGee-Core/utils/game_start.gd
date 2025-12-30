extends CanvasLayer

signal game_started()
signal game_ended()

@export var gameover_screen: Control
@onready var game_time: Timer = $GameTime
@onready var start_time: Timer = $StartTime

var player_nodes: Array[Node3D]= []

func _ready() -> void:
	gameover_screen.hide()
	start_time.timeout.connect(func(): _start())
	game_time.timeout.connect(func(): _end_game())

func _start():
	game_started.emit()
	game_time.start()
	for p in player_nodes:
		if p.has_method("set_locked"):
			p.set_locked(false)

func _end_game():
	game_ended.emit()
	for p in player_nodes:
		if p.has_method("set_locked"):
			p.set_locked(true)
	
	gameover_screen.show()

func start_game(players: Array[Node3D]):
	gameover_screen.hide()
	player_nodes = players
	start_time.start()
