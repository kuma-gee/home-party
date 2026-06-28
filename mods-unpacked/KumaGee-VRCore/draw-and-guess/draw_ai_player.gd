class_name DrawAIPlayer
extends DrawPlayerUI

## AI-controlled player that simulates a real phone player.
## Does not require a GameClient — overrides methods that would send network messages.

func setup_ai(idx: int, uuid_str: String, color: Color) -> void:
	uuid = uuid_str
	game_client = null
	if player_icon is PlayerIcon:
		player_icon.color = color
		player_icon.icon.text = "P%d" % (idx + 1)
	move_in()

func mark_word_submitted() -> void:
	checkmark.show()
	set_ready()
