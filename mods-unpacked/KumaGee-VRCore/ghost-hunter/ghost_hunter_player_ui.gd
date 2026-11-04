class_name GhostHunterPlayerUI
extends JoinedPlayer


func _ready() -> void:
	super()
	# Phones are controller-only (ADR-0001): generic joystick + A/B layout.
	LobbyServer.send_layout("joystick")
