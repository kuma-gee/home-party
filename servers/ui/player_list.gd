extends Control

func _ready() -> void:
	LobbyServer.update_players_list.connect(_on_update_players_list)

func _on_update_players_list(players: Array) -> void:
	for child in get_children():
		child.queue_free()
	
	for player_data in players:
		var player_label = Label.new()
		if player_data.is_empty():
			player_label.text = "Player %d: (awaiting data)" % player_data.peer_id
		else:   
			player_label.text = "Player %d: %s" % [player_data.peer_id, player_data.name]

		add_child(player_label)
