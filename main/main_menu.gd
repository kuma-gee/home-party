extends Control

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

func _on_game_button_toggled(source: BaseButton, pressed: bool) -> void:
	if not pressed:
		return
	
	for btn in game_list.get_children():
		if btn != source:
			btn.set_pressed_no_signal(false)
			btn.modulate = Color.DIM_GRAY
