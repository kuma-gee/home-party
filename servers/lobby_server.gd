extends Node

signal update_players_list(players: Array)

enum Message {
	Id,
}

const PORT = 14412

var players = {}
var socket = WebSocketMultiplayerPeer.new()
var logger = KumaLog.new("WebRtcSignaling")

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

func _send_to_peer(id: int, data: Dictionary):
	socket.get_peer(id).put_packet(JSON.stringify(data).to_utf8_buffer())

func _process(_delta: float) -> void:
	socket.poll()

	while socket.get_available_packet_count():
		var dataStr = socket.get_packet().get_string_from_utf8()
		logger.debug("Received message: %s" % dataStr)

		var data = JSON.parse_string(dataStr)
		_on_message_received(data)

func _on_message_received(data: Dictionary):
	if data.has("msg"):
		if data.msg == LobbyServer.Message.Id:
			_on_id_message(data)

func _on_id_message(data: Dictionary):
	var peer_id = data.peer_id
	players[peer_id] = data

func _update_players_list():
	var players_list = []
	for id in players.keys():
		var player_data = players[id]
		players_list.append(player_data)
	update_players_list.emit(players_list)

#func send_session(path, type, sdp):
	#var other = _find_other(path)
	#assert(other != "")
	#get_node(other).peer.set_remote_description(type, sdp)
#
#func send_candidate(path, mid, index, sdp):
	#var other = _find_other(path)
	#assert(other != "")
	#get_node(other).peer.add_ice_candidate(mid, index, sdp)
