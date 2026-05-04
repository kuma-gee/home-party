extends Node

signal player_connected(data: Dictionary)
signal player_disconnected(client_id: String)
signal updated_players_list(players: Array)

signal received_candidate(client_id: String, mid: String, index: int, sdp: String)
signal received_session(client_id: String, type: String, sdp: String)

enum Message {
	Id,
	GameClientSession,
	GameClientIceCandidate,
	InputLayout,
}

const PORT = 14412
@export_enum("joystick", "buttons") var input_layout: String = "joystick"

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

func send_layout(layout: String):
	input_layout = layout
	for peer_id in peer_to_uuid.keys():
		_send_to_peer(peer_id, {
			"msg": Message.InputLayout,
			"layout": input_layout,
		})

func _peer_connected(id: int):
	logger.info("Peer connected: %d" % id)
	peer_to_uuid[id] = ""

	_send_to_peer(id, {
		"msg": Message.Id,
		"id": id,
		"number": peer_to_uuid.size() - 1,
	})

	_send_to_peer(id, {
		"msg": Message.InputLayout,
		"layout": input_layout,
	})

func _peer_disconnected(id: int):
	logger.info("Peer disconnected: %d" % id)
	var uuid = peer_to_uuid.get(id, "")
	if uuid != "":
		players.erase(uuid)
		update_players_list()
		
	player_disconnected.emit(uuid)
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
	if not data.has("msg"): return

	var peer = int(data.get("peer_id", -1))
	match int(data.msg):
		Message.Id:
			_on_id_message(data)
		Message.GameClientSession:
			var client_id = peer_to_uuid.get(peer, "")
			if client_id == "":
				logger.error("Received session message from unknown peer %d" % peer)
				return
			received_session.emit(client_id, data.type, data.sdp)
		Message.GameClientIceCandidate:
			var client_id = peer_to_uuid.get(peer, "")
			if client_id == "":
				logger.error("Received ICE candidate message from unknown peer %d" % peer)
				return
			received_candidate.emit(client_id, data.mid, int(data.index), data.sdp)

func _on_id_message(data: Dictionary):
	var peer_id = int(data.peer_id)
	var uuid = data.get("client_id", "")
	
	if uuid == "":
		logger.error("Received Id message without client_id from peer %d" % peer_id)
		return
	
	peer_to_uuid[peer_id] = uuid
	players[uuid] = data
	player_connected.emit(data)
	update_players_list()

func get_player_idx(uuid: String) -> int:
	var data = players.get(uuid, null)
	if data == null:
		logger.error("get_player_idx: No player data found for UUID %s" % uuid)
		return -1
	return data.number

func update_players_list():
	var players_list = []
	for uuid in players.keys():
		var player_data = players[uuid]
		players_list.append(player_data)
	
	logger.info("Update players: %s" % [players.keys()])
	updated_players_list.emit(players_list)

func get_peer_id_from_uuid(uuid: String) -> int:
	for peer_id in peer_to_uuid.keys():
		if peer_to_uuid[peer_id] == uuid:
			return peer_id
	return -1

func send_session(client_id: String, type, sdp):
	_send_to_peer(get_peer_id_from_uuid(client_id), {
		"msg": Message.GameClientSession,
		"type": type,
		"sdp": sdp,
	})

func send_candidate(client_id: String, mid, index, sdp):
	_send_to_peer(get_peer_id_from_uuid(client_id), {
		"msg": Message.GameClientIceCandidate,
		"mid": mid,
		"index": index,
		"sdp": sdp,
	})

func get_player_data(uuid: String) -> Dictionary:
	return players.get(uuid, {})
