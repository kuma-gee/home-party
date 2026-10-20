class_name VortexVolleyPlayerUI
extends JoinedPlayer

const MAX_LIVES: int = 3

@export var lives_label: Label

## Phone players ready up with A/B during the prepare phase. The same buttons
## launch orbs once the round is running, so readying is only meaningful before
## the start — repeated presses just re-assert readiness.
func _ready() -> void:
	super()
	if game_client:
		game_client.primary_action_pressed.connect(_ready_up)
		game_client.secondary_action_pressed.connect(_ready_up)
	_update_lives_label(MAX_LIVES)

func _ready_up() -> void:
	if not is_ready:
		set_ready()

func set_lives(lives: int) -> void:
	_update_lives_label(lives)

func _update_lives_label(lives: int) -> void:
	if not lives_label:
		return
	lives_label.text = "♥".repeat(clampi(lives, 0, MAX_LIVES)) \
		+ "♡".repeat(maxi(0, MAX_LIVES - lives))
	lives_label.modulate = Color(0.4, 0.4, 0.4) if lives <= 0 else Color.WHITE
