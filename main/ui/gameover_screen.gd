class_name GameoverPanel
extends Control

signal back_to_menu()
signal restart_game()

#@export var label: Label
#@export var menu_button: Button
#@export var restart_button: Button

@onready var gameover_label: Label = $VBoxContainer/GameoverLabel
@onready var menu_button: Button = $VBoxContainer/MenuButton
@onready var restart_button: Button = $VBoxContainer/RestartButton


func _ready() -> void:
	if menu_button:
		menu_button.pressed.connect(func(): back_to_menu.emit())
	if restart_button:
		restart_button.pressed.connect(func(): restart_game.emit())

func set_title(txt: String):
	gameover_label.text = txt
