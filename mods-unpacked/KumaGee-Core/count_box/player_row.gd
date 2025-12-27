class_name PlayerRow
extends AnimeControl

@export var text_label: Label
@export var name_label: Label
@export var texture_rect: TextureRect

var count_player: CountPlayer

func _ready() -> void:
	set_disabled(true)
	count_player.locked_changed.connect(func(l): set_disabled(not l))
	count_player.count_changed.connect(func(c): set_text(c))
	count_player.winner_changed.connect(func(w): set_winner_state(w))
	count_player.resetted.connect(func(): scale_to(Vector2.ONE))
	#var data = LobbyServer.get_player_data(game_client.uuid)
	#name_label.text = "%s" % data.name

func set_winner_state(winner: bool):
	if not count_player.started:
		return
	
	if winner:
		scale_to(Vector2(1.5, 1.5))
	else:
		set_disabled(true)

func set_text(txt):
	text_label.text = "%s" % txt
