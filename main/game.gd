extends Node

@export var start_button: Button
@export var game_list: Control
@export var game_button: PackedScene

@export var menu_world: PackedScene
@export var menu: Control
@export var menu_viewport: SubViewport

@onready var game_loader: GameLoader = $GameLoader
@onready var game_mode: GameMode = $GameMode
#@onready var vr_space: Node3D = $VRSpace

var world: MenuWorld
var logger := KumaLog.new("Game")

func _ready() -> void:
	game_mode.started.connect(func(): menu.hide())
	game_mode.finished.connect(_on_finish_game)
	start_button.pressed.connect(_on_start_game)
	
	for game in game_loader.list_games():
		var btn = game_button.instantiate()
		btn.game = game
		game_list.add_child(btn)
	
	_create_world()

func _create_world():
	world = menu_world.instantiate()
	world.set_viewport(menu_viewport)
	add_child(world)

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
	world.queue_free()
	
	#vr_space.process_mode = Node.PROCESS_MODE_DISABLED
	#vr_space.hide()

func _on_finish_game():
	menu.show()
	_create_world()
	
	#vr_space.process_mode = Node.PROCESS_MODE_INHERIT
	#vr_space.show()
