@tool
class_name XRMenuButton
extends XRToolsInteractableArea

@export var label: Label3D
@export var mesh: MeshInstance3D
@export var text = ""

func _ready() -> void:
	label.text = text
