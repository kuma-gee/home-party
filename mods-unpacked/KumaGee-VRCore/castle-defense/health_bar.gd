extends ProgressBar

@export var hurtbox: HurtBox

func _ready() -> void:
	if not hurtbox.health_changed.is_connected(_update):
		hurtbox.health_changed.connect(_update)
	max_value = hurtbox.health
	_update()

func _update():
	max_value = hurtbox.health
	value = hurtbox.current_health
