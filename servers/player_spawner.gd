extends Node3D

@export var lobby_server: LobbyServer
@export var player_scene: PackedScene

func _ready() -> void:
	lobby_server.player_connected.connect(spawn_peer)
	lobby_server.player_disconnected.connect(remove_peer)
	lobby_server.received_candidate.connect(_on_received_candidate)
	lobby_server.received_session.connect(_on_received_session)

func _on_received_candidate(peer: int, mid: String, index: int, sdp: String):
	var player = get_node_or_null("%s" % peer)
	if player:
		player.game_client.add_ice_candidate(mid, index, sdp)

func _on_received_session(peer: int, type: String, sdp: String):
	var player = get_node_or_null("%s" % peer)
	if player:
		player.game_client.set_session(type, sdp)

func spawn_peer(data: Dictionary):
	var peer_id = int(data.peer_id)
	var player = player_scene.instantiate() as Player
	player.name = "%s" % peer_id
	player.data = data
	player.send_candidate.connect(func(mid: String, index: int, sdp: String):
		lobby_server.send_candidate(peer_id, mid, index, sdp)
	)
	player.send_session.connect(func(type: String, sdp: String):
		lobby_server.send_session(peer_id, type, sdp)
	)
	add_child(player)

func remove_peer(peer_id: int):
	var player = get_node_or_null("%s" % peer_id)
	if player:
		player.queue_free()
