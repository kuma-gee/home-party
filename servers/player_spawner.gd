#extends Node
#
#@export var player_scene: PackedScene
#
#func _ready() -> void:
	#LobbyServer.player_connected.connect(spawn_peer)
	#LobbyServer.player_disconnected.connect(remove_peer)
	#LobbyServer.received_candidate.connect(_on_received_candidate)
	#LobbyServer.received_session.connect(_on_received_session)
#
#func _on_received_candidate(uuid: String, mid: String, index: int, sdp: String):
	#var player = get_node_or_null("%s" % uuid)
	#if player:
		#player.game_client.add_ice_candidate(mid, index, sdp)
#
#func _on_received_session(uuid: String, type: String, sdp: String):
	#var player = get_node_or_null("%s" % uuid)
	#if player:
		#player.game_client.set_session(type, sdp)
#
#func spawn_peer(data: Dictionary):
	#var uuid = data.get("client_id", "")
	#if uuid == "":
		#print("Error: No client_id in player data")
		#return
		#
	#var peer_id = int(data.peer_id)
	#var player = player_scene.instantiate() as Player
	#player.name = "%s" % uuid  # Use UUID as node name
	#player.data = data
	#player.send_candidate.connect(func(mid: String, index: int, sdp: String):
		#LobbyServer.send_candidate(peer_id, mid, index, sdp)
	#)
	#player.send_session.connect(func(type: String, sdp: String):
		#LobbyServer.send_session(peer_id, type, sdp)
	#)
	#add_child(player)
#
#func remove_peer(uuid: String):
	#var player = get_node_or_null("%s" % uuid)
	#if player:
		#player.queue_free()
