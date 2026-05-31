class_name DesktopGameover
extends Control

@export var score_table: ScoreTable

func _ready() -> void:
	hide()

func show_gameover(title: String, rankings: Array) -> void:
	score_table.set_title(title)
	score_table.set_rankings(rankings)
	show()
