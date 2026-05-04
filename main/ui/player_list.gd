class_name PlayerList
extends Control

const COLORS = [
	Color(1, 0, 0, 1),
	Color(0.10830901, 0.44832176, 0.90811163, 1),
	Color(0.14999998, 1, 0, 1),
	Color(1, 0.9607843, 0.2509804, 1),
	Color(0.4000001, 0, 1, 1),
	Color(1, 0.61960787, 0.011764706, 1),
	Color(0, 0.93333334, 1, 1),
	Color(0.9019608, 0.27058825, 1, 1)
]

static func get_color(idx: int) -> Color:
	return COLORS[idx % COLORS.size()]

@export var player_scene: PackedScene

func _ready() -> void:
	LobbyServer.updated_players_list.connect(_on_update_players_list)
	await get_tree().create_timer(2.0).timeout
	LobbyServer.update_players_list()

func _on_update_players_list(players: Array) -> void:
	# Example: [{ "msg": 0.0, "peer_id": 1392038853.0, "client_id": "21f81607-24c5-4cac-917f-e61835a63d2b", "name": "asd" }]
	var current_players = []
	for player_data in players:
		current_players.append(player_data.client_id)
		var existing = _find_existing_node(player_data.client_id)
		if existing:
			existing.update_data(player_data)
		else:
			var new_node = player_scene.instantiate() as JoinedPlayer
			new_node.update_data(player_data)
			add_child(new_node)
			new_node.move_in()
		
		await get_tree().create_timer(0.1).timeout
	
	# Remove players that left
	for child in get_children():
		if child is JoinedPlayer and child.uuid not in current_players:
			child.move_out()

func _find_existing_node(uuid: String):
	for child in get_children():
		if child is JoinedPlayer and child.uuid == uuid:
			return child
	return null
