class_name LobbyServer
extends Node

signal player_connected(data: Dictionary)
signal player_disconnected(id: int)
signal update_players_list(players: Array)

signal received_candidate(peer: int, mid: String, index: int, sdp: String)
signal received_session(peer: int, type: String, sdp: String)

enum Message {
	Id,
	GameClientSession,
	GameClientIceCandidate,
}

const PORT = 14412

var players = {}
var socket = WebSocketMultiplayerPeer.new()
var logger = KumaLog.new("LobbyServer")

func _ready() -> void:
	socket.create_server(PORT)
	socket.peer_connected.connect(_peer_connected)
	socket.peer_disconnected.connect(_peer_disconnected)
	logger.info("Creating signaling server on port %d" % PORT)

func _peer_connected(id: int):
	logger.info("Peer connected: %d" % id)
	players[id] = {}

	_send_to_peer(id, {
		"msg": Message.Id,
		"id": id,
	})

func _peer_disconnected(id: int):
	logger.info("Peer disconnected: %d" % id)
	players.erase(id)
	player_disconnected.emit(id)
	_update_players_list()

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
			LobbyServer.Message.Id:
				_on_id_message(data)
			LobbyServer.Message.GameClientSession:
				received_session.emit(int(data.peer_id), data.type, data.sdp)
			LobbyServer.Message.GameClientIceCandidate:
				received_candidate.emit(int(data.peer_id), data.mid, int(data.index), data.sdp)

func _on_id_message(data: Dictionary):
	var peer_id = int(data.peer_id)
	players[peer_id] = data
	player_connected.emit(data)
	_update_players_list()

func _update_players_list():
	var players_list = []
	for id in players.keys():
		var player_data = players[id]
		players_list.append(player_data)
	
	logger.info("Update players: %s" % [players.keys()])
	update_players_list.emit(players_list)

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
