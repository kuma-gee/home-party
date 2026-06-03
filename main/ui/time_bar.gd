extends ProgressBar

@export var timer: Timer

func _process(_delta: float) -> void:
	if timer.is_stopped(): return
	
	var p = timer.time_left / timer.wait_time
	value = p * max_value
