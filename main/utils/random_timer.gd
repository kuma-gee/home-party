class_name RandomTimer
extends Timer

@export var min_time := 0.5
@export var max_time := 1.0

func _ready() -> void:
	if not one_shot:
		timeout.connect(start_random)

func start_random() -> void:
	var time = randf_range(min_time, max_time)
	start(time)
