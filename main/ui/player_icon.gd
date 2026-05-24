class_name PlayerIcon
extends ColorRect

@export var icon: MaterialIcon

func update(data: Dictionary):
	color = PlayerList.get_color(PlayerManager.get_player_idx(data.client_id))
	icon.code = data.icon
