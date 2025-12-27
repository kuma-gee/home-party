extends Node

var logger := KumaLog.new("PlayerManager")

func _ready() -> void:
	LobbyServer.player_connected.connect(create_peer)
	LobbyServer.player_disconnected.connect(remove_peer)
	LobbyServer.received_candidate.connect(_on_received_candidate)
	LobbyServer.received_session.connect(_on_received_session)

func _on_received_candidate(peer_id: int, mid: String, index: int, sdp: String):
	var player = get_node_or_null("%s" % peer_id)
	if player:
		player.add_ice_candidate(mid, index, sdp)
	else:
		logger.warn("Failed to find player with id %s to set ice candidate" % peer_id)

func _on_received_session(peer_id: int, type: String, sdp: String):
	var player = get_node_or_null("%s" % peer_id)
	if player:
		player.set_session(type, sdp)
	else:
		logger.warn("Failed to find player with id %s to set session" % peer_id)

func create_peer(data: Dictionary):
	var peer_id = int(data.get("peer_id", -1))
	if peer_id < 0:
		print("Error: No peer_id in player data")
		return
		
	var player = GameClient.new()
	player.name = "%s" % peer_id
	player.uuid = data.get("client_id")
	player.send_candidate.connect(func(mid: String, index: int, sdp: String): LobbyServer.send_candidate(peer_id, mid, index, sdp))
	player.send_session.connect(func(type: String, sdp: String): LobbyServer.send_session(peer_id, type, sdp))
	add_child(player)

func remove_peer(peer_id: int):
	var player = get_node_or_null("%s" % peer_id)
	if player:
		player.queue_free()
	else:
		logger.warn("Failed to remove player with id %s" % peer_id)

func get_players() -> Array[GameClient]:
	var result: Array[GameClient] = []
	for child in get_children():
		if child is GameClient:
			result.append(child as GameClient)
	return result
