class_name MainMenu
extends Control

signal start_game(res: GameResource)

@export var game_button: PackedScene
@onready var start_button = %StartGame
@onready var game_list = %GameList
@onready var game_loader: GameLoader = $GameLoader

func _ready() -> void:
	for game in game_loader.list_games():
		var btn = game_button.instantiate()
		btn.game = game
		game_list.add_child(btn)
		btn.toggled.connect(func(pressed: bool): _on_game_button_toggled(btn, pressed))
	
	start_button.pressed.connect(_on_start_button_pressed)
	start_button.disabled = true

func _on_start_button_pressed() -> void:
	#if LobbyServer.players.is_empty():
		#return

	var game = _get_selected_game()
	if not game: return
	
	start_game.emit(game)

func _get_selected_game() -> GameResource:
	for btn in game_list.get_children():
		if btn.button_pressed:
			return btn.game
	return null

func _on_game_button_toggled(source: BaseButton, pressed: bool) -> void:
	if not pressed:
		start_button.disabled = true
		return
	
	for btn in game_list.get_children():
		if btn != source:
			btn.set_pressed_no_signal(false)
			btn.modulate = Color.DIM_GRAY

	start_button.disabled = false
