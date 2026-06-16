class_name HideAndSeekPlayerUI
extends JoinedPlayer


func _ready() -> void:
	super()
	# Send the hide-and-seek layout for mobile UI
	LobbyServer.send_layout("hide_and_seek")
