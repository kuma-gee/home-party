class_name GameDetailsPanel
extends Control

@export var name_label: Label
@export var desc_label: Label
@export var player_label: Label
@export var bg_image: TextureRect
@export var demo_label: Label

func _ready() -> void:
	pass

func update_details(game: GameResource) -> void:
	if not game:
		hide()
		return

	name_label.text = game.name
	desc_label.text = game.description
	if demo_label:
		demo_label.visible = Env.is_demo() and not Env.is_game_available(game)

	if game.max_recommended_players == -1:
		player_label.text = "👤 %d+ players" % game.min_recommended_players
	else:
		player_label.text = "👤 %d–%d players" % [game.min_recommended_players, game.max_recommended_players]

	#bg_image.texture = game.vr_preview
	show()
