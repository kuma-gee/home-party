class_name PlayerIcon
extends ColorRect

@export var icon: Label

func update(data: Dictionary):
	var idx = PlayerManager.get_player_idx(data.client_id)
	if idx < 0:
		return
	color = PlayerList.get_color(idx)
	icon.text = "P%s" % (idx + 1)
