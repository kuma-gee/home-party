@tool
class_name GameSelectArea
extends XRToolsPickable

@onready var icon_root: Node3D = $IconRoot

var game: GameResource

func _ready() -> void:
	super()
	var node = game.icon.instantiate()
	icon_root.add_child(node)
