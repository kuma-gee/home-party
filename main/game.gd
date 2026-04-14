class_name Game
extends Node

signal started()
signal finished()

@export var start_button: Button
@export var game_list: Control
@export var game_button: PackedScene

@export var menu_world: PackedScene
@export var menu: Control
@export var menu_viewport: SubViewport

@onready var game_loader: GameLoader = $GameLoader

var world: MenuWorld
var logger := KumaLog.new("Game")
var game_node: BaseGame
var playing := false

func _ready() -> void:
	started.connect(func(): menu.hide())
	finished.connect(_on_finish_game)
	start_button.pressed.connect(_on_start_game)

	for game in game_loader.list_games():
		var btn = game_button.instantiate()
		btn.game = game
		game_list.add_child(btn)
		btn.toggled.connect(func(pressed: bool): _on_game_button_toggled(btn, pressed))

	_create_world()

func _on_game_button_toggled(source: BaseButton, pressed: bool) -> void:
	if not pressed:
		return
	for btn in game_list.get_children():
		if btn != source:
			btn.set_pressed_no_signal(false)
			btn.modulate = Color.DIM_GRAY

func _create_world() -> void:
	world = menu_world.instantiate()
	world.set_viewport(menu_viewport)
	add_child(world)

func _on_start_game() -> void:
	if LobbyServer.players.is_empty():
		logger.error("No players to play the game!")
		return

	var selected: GameResource = null
	for btn in game_list.get_children():
		if btn.button_pressed:
			selected = btn.game
			break

	if selected == null:
		logger.error("No game selected!")
		return

	PlayerManager.start_game()
	start_game_resource(selected)
	world.queue_free()

func start_game_resource(res: GameResource) -> void:
	playing = true
	started.emit()
	_create_game(res)

func _create_game(res: GameResource) -> void:
	if game_node != null:
		game_node.queue_free()

	game_node = res.scene.instantiate() as BaseGame
	add_child(game_node)

	var players = PlayerManager.get_players()
	var game_setup = GameSetup.new()
	game_node.game_finished.connect(func(): end_game())
	game_node.back_to_menu.connect(func(): end_game())
	game_node.game_restart.connect(func(): _create_game(res))
	game_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	game_node.start_game(players, game_setup)

func end_game() -> void:
	if game_node:
		game_node.queue_free()
		game_node = null

	var players = PlayerManager.get_players()
	for p in players:
		p.reset()

	playing = false
	finished.emit()

func _on_finish_game() -> void:
	menu.show()
	_create_world()
