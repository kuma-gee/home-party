extends Label

@export var timer: Timer

func _process(delta: float) -> void:
	if timer.time_left > 0 and not timer.is_stopped():
		text = "%.0f" % timer.time_left
	else:
		text = "00"
