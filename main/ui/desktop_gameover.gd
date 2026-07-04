class_name DesktopGameover
extends Control

@export var leaderboard: Leaderboard
@export var background: ColorRect
@export var container: CenterContainer

func _ready() -> void:
	hide()

func show_leaderboard(title: String, entries: Array) -> void:
	leaderboard.show()
	leaderboard.set_title(title)
	leaderboard.set_entries(entries)

	background.modulate = Color.TRANSPARENT
	container.modulate = Color.TRANSPARENT
	show()

	var tw = create_tween()
	tw.tween_property(background, "modulate", Color.WHITE, 0.5)
	tw.tween_property(container, "modulate", Color.WHITE, 0.5).set_delay(0.2)
