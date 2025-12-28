extends Node

signal player_connected(data: Dictionary)
signal player_disconnected(peer_id: int)
signal update_players_list(players: Array)

signal received_candidate(peer_id: int, mid: String, index: int, sdp: String)
signal received_session(peer_id: int, type: String, sdp: String)

enum Message {
	Id,
	GameClientSession,
	GameClientIceCandidate,
}

const PORT = 14412

var players = {}  # Dictionary[String, Dictionary] - UUID -> player data
var peer_to_uuid = {}  # Dictionary[int, String] - peer_id -> UUID mapping for WebRTC
var socket = WebSocketMultiplayerPeer.new()
var logger = KumaLog.new("LobbyServer")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	socket.peer_connected.connect(_peer_connected)
	socket.peer_disconnected.connect(_peer_disconnected)
	socket.create_server(PORT, "*")
	logger.info("Creating signaling server on port %s" % [PORT])

func _peer_connected(id: int):
	logger.info("Peer connected: %d" % id)
	peer_to_uuid[id] = ""

	_send_to_peer(id, {
		"msg": Message.Id,
		"id": id,
	})

func _peer_disconnected(id: int):
	logger.info("Peer disconnected: %d" % id)
	var uuid = peer_to_uuid.get(id, "")
	if uuid != "":
		players.erase(uuid)
		_update_players_list()
		
	player_disconnected.emit(id)
	peer_to_uuid.erase(id)

func _send_to_peer(id: int, data: Dictionary):
	socket.get_peer(id).put_packet(JSON.stringify(data).to_utf8_buffer())
	logger.info("Sent message to peer %d: %s" % [id, data])

func _process(_delta: float) -> void:
	socket.poll()

	while socket.get_available_packet_count():
		var dataStr = socket.get_packet().get_string_from_utf8()
		logger.debug("Received message: %s" % dataStr)

		var data = JSON.parse_string(dataStr)
		_on_message_received(data)

func _on_message_received(data: Dictionary):
	if data.has("msg"):
		match int(data.msg):
			Message.Id:
				_on_id_message(data)
			Message.GameClientSession:
				var peer_id = int(data.peer_id)
				received_session.emit(peer_id, data.type, data.sdp)
			Message.GameClientIceCandidate:
				var peer_id = int(data.peer_id)
				received_candidate.emit(peer_id, data.mid, int(data.index), data.sdp)

func _on_id_message(data: Dictionary):
	var peer_id = int(data.peer_id)
	var uuid = data.get("client_id", "")
	
	if uuid == "":
		logger.error("Received Id message without client_id from peer %d" % peer_id)
		return
	
	# Store the peer_id -> UUID mapping
	peer_to_uuid[peer_id] = uuid
	
	# Store player data by UUID
	players[uuid] = data
	player_connected.emit(data)
	_update_players_list()

func _update_players_list():
	var players_list = []
	for uuid in players.keys():
		var player_data = players[uuid]
		players_list.append(player_data)
	
	logger.info("Update players: %s" % [players.keys()])
	update_players_list.emit(players_list)

func get_peer_id_from_uuid(uuid: String) -> int:
	for peer_id in peer_to_uuid.keys():
		if peer_to_uuid[peer_id] == uuid:
			return peer_id
	return -1

func send_session(path, type, sdp):
	_send_to_peer(int(path), {
		"msg": Message.GameClientSession,
		"type": type,
		"sdp": sdp,
	})

func send_candidate(path, mid, index, sdp):
	_send_to_peer(int(path), {
		"msg": Message.GameClientIceCandidate,
		"mid": mid,
		"index": index,
		"sdp": sdp,
	})

func get_player_data(uuid: String) -> Dictionary:
	return players.get(uuid, {})
