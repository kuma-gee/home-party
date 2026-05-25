class_name GameDetailsPanel
extends Control

@export var name_label: Label
@export var desc_label: Label
@export var player_label: Label
@export var bg_image: TextureRect

func update_details(game: GameResource) -> void:
	if not game:
		hide()
		return

	name_label.text = game.name
	desc_label.text = game.description

	if game.max_recommended_players == -1:
		player_label.text = "👤 %d+ players" % game.min_recommended_players
	else:
		player_label.text = "👤 %d–%d players" % [game.min_recommended_players, game.max_recommended_players]

	bg_image.texture = game.vr_preview
	show()
