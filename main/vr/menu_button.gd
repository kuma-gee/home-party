@tool
class_name XRMenuButton
extends XRToolsInteractableArea

@export var label: Label3D
@export var mesh: MeshInstance3D
@export var text = "":
	set(v):
		text = v
		if label:
			label.text = v

func _ready() -> void:
	label.text = text
