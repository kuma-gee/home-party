extends Node3D

@export var start_game_btn: Button

func _ready() -> void:
	start_game_btn.pressed.connect(_on_start_game)
	
func _on_start_game():
	pass
