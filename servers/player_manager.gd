extends Node

@export var lobby_server: LobbyServer
@export var player_scene: PackedScene

func _ready() -> void:
	lobby_server.player_connected.connect(create_peer)
	lobby_server.player_disconnected.connect(remove_peer)
	lobby_server.received_candidate.connect(_on_received_candidate)
	lobby_server.received_session.connect(_on_received_session)

func _on_received_candidate(uuid: String, mid: String, index: int, sdp: String):
	var player = get_node_or_null("%s" % uuid)
	if player:
		player.add_ice_candidate(mid, index, sdp)

func _on_received_session(uuid: String, type: String, sdp: String):
	var player = get_node_or_null("%s" % uuid)
	if player:
		player.set_session(type, sdp)

func create_peer(data: Dictionary):
	var uuid = data.get("client_id", "")
	if uuid == "":
		print("Error: No client_id in player data")
		return
		
	var peer_id = int(data.peer_id)
	var player = GameClient.new()
	player.send_candidate.connect(func(mid: String, index: int, sdp: String): lobby_server.send_candidate(peer_id, mid, index, sdp))
	player.send_session.connect(func(type: String, sdp: String): lobby_server.send_session(peer_id, type, sdp))
	add_child(player)

func remove_peer(uuid: String):
	var player = get_node_or_null("%s" % uuid)
	if player:
		player.queue_free()

func create_3d_players(root: Node3D):
	for child in get_children():
		if child is GameClient:
			var player = player_scene.instantiate() as Player
			player.name = "%s" % child.name
			player.game_client = child
			root.add_child(player)

