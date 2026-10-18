class_name VortexVolleyPlayerUI
extends JoinedPlayer

## Phone players ready up with A/B during the prepare phase. The same buttons
## launch orbs once the round is running, so readying is only meaningful before
## the start — repeated presses just re-assert readiness.
func _ready() -> void:
	super()
	if game_client:
		game_client.primary_action_pressed.connect(_ready_up)
		game_client.secondary_action_pressed.connect(_ready_up)

func _ready_up() -> void:
	if not is_ready:
		set_ready()
