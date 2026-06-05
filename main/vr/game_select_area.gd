@tool
class_name GameSelectArea
extends XRToolsPickable

@export var icon_viewport: SubViewport
@export var label: Label

var game: GameResource

func _ready() -> void:
	super()
	if game.icon:
		var node = game.icon.instantiate()
		icon_viewport.add_child(node)
	label.text = game.name
