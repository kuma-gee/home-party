class_name GameoverPanel
extends Control

signal back_to_menu()
signal restart_game()

@export var label: Label
@export var menu_button: Button
@export var restart_button: Button

func _ready() -> void:
	menu_button.pressed.connect(func(): back_to_menu.emit())
	restart_button.pressed.connect(func(): restart_game.emit())

func set_title(txt: String):
	label.text = txt
