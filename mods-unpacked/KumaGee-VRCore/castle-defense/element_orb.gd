class_name ElementOrb
extends Area3D

@export var element := Arrow.Element.FIRE
@export var visual: MeshInstance3D

func _ready() -> void:
	ArrowElement.update_visual(visual, element)
