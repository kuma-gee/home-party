class_name ElementOrb
extends Area3D

@export var element := Arrow.Element.FIRE
@export var visual: MeshInstance3D
@export var cooldown_time := 1.0
@export var color_rect: ColorRect

@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	ArrowElement.update_visual(visual, element)
	#color_rect.color = ArrowElement.get_element_color(element)

func is_loaded():
	return cooldown_timer.is_stopped()

func fired():
	cooldown_timer.start(cooldown_time)

func set_element(new_element: Arrow.Element) -> void:
	element = new_element
	ArrowElement.update_visual(visual, element)
