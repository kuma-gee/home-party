extends ProgressBar

@export var hurtbox: HurtBox

func _ready() -> void:
	await hurtbox.ready
	hurtbox.health_changed.connect(_update)
	
	max_value = hurtbox.health
	_update()

func _update():
	value = hurtbox.current_health
