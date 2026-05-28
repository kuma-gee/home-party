@tool
class_name GameSelectArea
extends XRToolsPickable

@onready var icon_root: Node3D = $IconRoot
@onready var sprite_3d: Sprite3D = $Sprite3D

var game: GameResource

func _ready() -> void:
	super()
	#var node = game.icon.instantiate()
	#icon_root.add_child(node)
	sprite_3d.texture = game.vr_preview
