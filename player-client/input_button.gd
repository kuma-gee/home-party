class_name InputButton
extends Button

@export var game_client: GameClient
@export var input_name: String = ""

func _ready() -> void:
	button_down.connect(_on_button_pressed)
	button_up.connect(_on_button_released)

func _on_button_pressed() -> void:
	game_client.send_input(input_name, true)

func _on_button_released() -> void:
	game_client.send_input(input_name, false)
