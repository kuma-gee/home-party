extends HBoxContainer

@export var hurt_box: HurtBox

func _ready() -> void:
	hurt_box.health_changed.connect(_update)

func _update():
	for i in get_child_count():
		get_child(i).visible = hurt_box.health > i
