extends Node

@export var start_button: Button
@export var game_list: Control
@export var game_button: PackedScene
@export var menu: Control

@onready var game_loader: GameLoader = $GameLoader
@onready var game_mode: GameMode = $GameMode

var logger := KumaLog.new("Game")

func _ready() -> void:
	game_mode.started.connect(func(): menu.hide())
	game_mode.finished.connect(func(): menu.show())
	start_button.pressed.connect(func(): _on_start_game())
	
	for game in game_loader.list_games():
		var btn = game_button.instantiate()
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
	
	PlayerManager.start_game()
	game_mode.start_games(games)
