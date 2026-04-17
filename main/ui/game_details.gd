extends Sprite3D

@export var name_label: Label
@export var desc_label: Label
@onready var sub_viewport: SubViewport = $SubViewport

func _ready() -> void:
	texture = sub_viewport.get_texture()
	hide()

func update_details(game: GameResource) -> void:
	if not game:
		name_label.text = ""
		desc_label.text = ""
		hide()
		return

	name_label.text = game.name
	desc_label.text = game.description
	show()
