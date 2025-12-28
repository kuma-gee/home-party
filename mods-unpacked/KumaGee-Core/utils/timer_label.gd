extends Label

@export var timer: Timer

func _process(_delta: float) -> void:
	if timer:
		visible = not timer.is_stopped()
		text = "%.0f" % timer.time_left
