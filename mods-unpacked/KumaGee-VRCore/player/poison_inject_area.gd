extends Area3D

func _ready() -> void:
	body_entered.connect(func(b):
		if b is FPSPlayer and not b.poison_timer.is_stopped():
			b.poison()
	)
