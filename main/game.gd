extends Node

@export var game_list: Control
@onready var game_loader: GameLoader = $GameLoader
@onready var game_mode: GameMode = $GameMode
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var logger := KumaLog.new("Game")

func _ready() -> void:
	game_mode.started.connect(func(): canvas_layer.hide())
	game_mode.finished.connect(func(): canvas_layer.show())
	
	for game in game_loader.list_games():
		var btn = Button.new()
		btn.text = game.name
		btn.pressed.connect(func(): _on_start_game(game))
		game_list.add_child(btn)

func _on_start_game(game: GameResource):
	if LobbyServer.players.is_empty():
		logger.error("No players to play the game!")
		return
	
	if not game.scene:
		logger.error("Game has no scene defined!")
		return
	
	logger.info("Starting game %s" % game.name)
	game_mode.start_game(game)
