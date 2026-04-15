extends Control

@export var player_scene: PackedScene

func _ready() -> void:
	LobbyServer.updated_players_list.connect(_on_update_players_list)
	await get_tree().create_timer(2.0).timeout
	LobbyServer.update_players_list()

func _on_update_players_list(players: Array) -> void:
	# Example: [{ "msg": 0.0, "peer_id": 1392038853.0, "client_id": "21f81607-24c5-4cac-917f-e61835a63d2b", "name": "asd" }]
	var current_playesr = []
	for player_data in players:
		current_playesr.append(player_data.client_id)
		var existing = _find_existing_node(player_data.client_id)
		if existing:
			existing.update_data(player_data)
		else:
			var new_node = player_scene.instantiate() as JoinedPlayer
			new_node.update_data(player_data)
			add_child(new_node)
			new_node.move_in()
	
	# Remove players that left
	for child in get_children():
		if child is JoinedPlayer and child.uuid not in current_playesr:
			child.move_out()

func _find_existing_node(uuid: String):
	for child in get_children():
		if child is JoinedPlayer and child.uuid == uuid:
			return child
	return null
