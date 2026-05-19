class_name PlayerSelect
extends ColorRect

@export var icon: Control

func _ready() -> void:
	set_ready(false)

func set_player(player: ClientController):
	color = PlayerList.get_color(PlayerManager.get_player_idx(player.uuid))

func set_ready(is_ready: bool):
	icon.visible = is_ready
