class_name VortexAIPlayer
extends VortexVolleyPlayerUI

## AI-controlled player entry shown in the shared player list. Has no GameClient,
## so it bypasses JoinedPlayer.update_data (which requires a PlayerManager entry).

func setup_ai(idx: int, uuid_str: String, color: Color) -> void:
	uuid = uuid_str
	game_client = null
	if player_icon:
		player_icon.color = color
		if player_icon.icon:
			player_icon.icon.text = "P%d" % (idx + 1)
	move_in()
	# AI is always ready so it never blocks the ready-gated start.
	set_ready()
