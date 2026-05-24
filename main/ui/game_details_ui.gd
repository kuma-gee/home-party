class_name GameDetailsUI
extends Control

@export var name_label: Label
@export var desc_label: Label

func _ready() -> void:
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
