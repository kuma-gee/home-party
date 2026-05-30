class_name GameoverPanel
extends Control

signal back_to_menu()
signal restart_game()

@onready var score_table: ScoreTable = $ScoreTable
@onready var menu_button: Button = $MenuButton
@onready var restart_button: Button = $RestartButton


func _ready() -> void:
	if menu_button:
		menu_button.pressed.connect(func(): back_to_menu.emit())
	if restart_button:
		restart_button.pressed.connect(func(): restart_game.emit())

func set_title(txt: String) -> void:
	score_table.set_title(txt)

func set_rankings(rankings: Array) -> void:
	score_table.set_rankings(rankings)
