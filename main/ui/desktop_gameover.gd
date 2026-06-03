class_name DesktopGameover
extends Control

@export var score_table: ScoreTable
@export var background: ColorRect
@export var container: CenterContainer

func _ready() -> void:
	hide()

func show_gameover(title: String, rankings: Array) -> void:
	score_table.set_title(title)
	score_table.set_rankings(rankings)

	background.modulate = Color.TRANSPARENT
	container.modulate = Color.TRANSPARENT
	show()

	var tw = create_tween()
	tw.tween_property(background, "modulate", Color.WHITE, 0.5)
	tw.tween_property(container, "modulate", Color.WHITE, 0.5).set_delay(0.2)
