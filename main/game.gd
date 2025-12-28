extends Node

@export var start_button: Button
@export var game_list: Control
@export var game_button: PackedScene

@onready var game_loader: GameLoader = $GameLoader
@onready var game_mode: GameMode = $GameMode
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var logger := KumaLog.new("Game")

func _ready() -> void:
	game_mode.started.connect(func(): canvas_layer.hide())
	game_mode.finished.connect(func(): canvas_layer.show())
	start_button.pressed.connect(func(): _on_start_game())
	
	for game in game_loader.list_games():
		var btn = game_button.instantiate()
		print(game)
		btn.game = game
		game_list.add_child(btn)

func _on_start_game():
	if LobbyServer.players.is_empty():
		logger.error("No players to play the game!")
		return
	
	var games: Array[GameResource] = []
	for btn in game_list.get_children():
		if btn.button_pressed:
			games.append(btn.game)
	
	if games.is_empty():
		logger.error("Game has no scene defined!")
		return
	
	game_mode.start_games(games)
