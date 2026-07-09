class_name DesktopGameover
extends Control

@export var leaderboard: Leaderboard
@export var background: ColorRect
@export var container: CenterContainer

func _ready() -> void:
	hide()

## populate_leaderboard, if given, is called with the Leaderboard node to
## fill it; omit it to hide the leaderboard and show just the title.
func show_gameover(title: String, populate_leaderboard: Callable = Callable()) -> void:
	leaderboard.set_title(title)
	if populate_leaderboard.is_valid():
		leaderboard.show()
		populate_leaderboard.call(leaderboard)
	else:
		leaderboard.hide()

	background.modulate = Color.TRANSPARENT
	container.modulate = Color.TRANSPARENT
	show()

	var tw = create_tween()
	tw.tween_property(background, "modulate", Color.WHITE, 0.5)
	tw.tween_property(container, "modulate", Color.WHITE, 0.5).set_delay(0.2)
