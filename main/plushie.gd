@tool
extends XRToolsPickable

@onready var player_tag: Label3D = $PlayerTag

var player_uuid: String
var player_index: int

func setup(idx: int, uuid: String, color: Color) -> void:
	player_index = idx
	player_uuid = uuid

	player_tag.text = "P%d" % (idx + 1)
	player_tag.modulate = color
