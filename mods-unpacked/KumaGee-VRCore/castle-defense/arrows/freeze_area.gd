extends Area3D

@export var freeze_time := 3.0
@export var slow_amount := 0.7

var enabled := false

func start_freeze():
	for body in get_overlapping_bodies():
		if body is FPSPlayer:
			body.freeze(freeze_time)
	enabled = true

func _process(_delta: float) -> void:
	if not enabled: return

	for body in get_overlapping_bodies():
		if body is FPSPlayer:
			body.apply_slow(slow_amount)
