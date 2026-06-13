@tool
extends XRToolsPickable

static var _model_offset := -1

@onready var models: Node3D = $Models
@onready var player_tag: Label3D = $PlayerTag

var player_uuid: String
var player_index: int

func setup(idx: int, uuid: String, color: Color) -> void:
	player_index = idx
	player_uuid = uuid
	name = "Plushie%s" % idx

	player_tag.text = "P%d" % (idx + 1)
	player_tag.modulate = color

	if _model_offset == -1:
		_model_offset = randi()

	for child in models.get_children():
		child.visible = false

	var count = models.get_child_count()
	models.get_child((idx + _model_offset) % count).visible = true

func get_visible_model() -> String:
	for child in models.get_children():
		if child.visible:
			return child.name
	return ""
