class_name ElementOrb
extends Area3D

const COOLDOWN_TIME = {
	Arrow.Element.FIRE: 1.0,
	Arrow.Element.ICE: 2.0,
	Arrow.Element.LIGHTNING: 4.0,
	Arrow.Element.WIND: 3.0,
	Arrow.Element.POISON: 2.5,
	Arrow.Element.VOID: 5.0
}

@export var element := Arrow.Element.FIRE
@export var visual: MeshInstance3D
@export var color_rect: ColorRect

@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	ArrowElement.update_visual(visual, element)
	cooldown_timer.timeout.connect(func(): ArrowElement.update_visual(visual, element))

func is_loaded():
	return cooldown_timer.is_stopped()

func fired():
	if element in COOLDOWN_TIME:
		cooldown_timer.start(COOLDOWN_TIME[element])
		ArrowElement.update_visual(visual, element, false)

func set_element(new_element: Arrow.Element) -> void:
	element = new_element
	ArrowElement.update_visual(visual, element)
