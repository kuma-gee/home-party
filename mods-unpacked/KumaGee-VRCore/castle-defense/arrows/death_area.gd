extends Area3D

func _ready() -> void:
	body_entered.connect(func(a):
		a.queue_free()
	)
