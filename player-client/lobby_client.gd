class_name LobbyClient
extends Node

signal connected_to_server()
signal received_candidate(mid: String, index: int, sdp: String)
signal received_session(type: String, sdp: String)

var socket = WebSocketMultiplayerPeer.new()
var logger = KumaLog.new("WebRtcClient")
var peer_id = -1

func is_socket_connected():
	return socket.get_connection_status() == WebSocketMultiplayerPeer.CONNECTION_CONNECTED

func _process(_delta):
	socket.poll()
	if is_socket_connected():
		while socket.get_available_packet_count() > 0:
			var dataStr = socket.get_packet().get_string_from_utf8()
			logger.debug("Received message from server: %s" % dataStr)

			var data = JSON.parse_string(dataStr)
			_on_message_received(data)

func _on_message_received(data: Dictionary):
	if data.has("msg"):
		match int(data.msg):
			LobbyServer.Message.Id:
				_on_id_message(data)
			LobbyServer.Message.GameClientSession:
				received_session.emit(data.type, data.sdp)
			LobbyServer.Message.GameClientIceCandidate:
				received_candidate.emit(data.mid, int(data.index), data.sdp)

func _on_id_message(data: Dictionary):
	peer_id = data.id
	connected_to_server.emit()

#region actions
func join_server(ip = "127.0.0.1"):
	if is_socket_connected():
		logger.warn("Already connected to server.")
		return
	
	var err = socket.create_client("ws://%s:%s" % [ip, LobbyServer.PORT], TLSOptions.client(Certificate.get_certificate()))
	if err == OK:
		logger.info("Connected to signaling server at %s:%d" % [ip, LobbyServer.PORT])
	else:
		logger.error("Failed to connect to signaling server: %s" % err)

	return err

func send_user_data(data: Dictionary):
	if not is_socket_connected():
		logger.warn("Cannot send user data, not connected to server.")
		return
	
	data["msg"] = LobbyServer.Message.Id
	_send_to_server(data)

func send_game_client_session(type: String, sdp: String):
	_send_to_server({
		"msg": LobbyServer.Message.GameClientSession,
		"type": type,
		"sdp": sdp,
	})

func send_game_client_ice_candidate(mid: String, index: int, sdp: String):
	_send_to_server({
		"msg": LobbyServer.Message.GameClientIceCandidate,
		"mid": mid,
		"index": index,
		"sdp": sdp,
	})

func _send_to_server(data: Dictionary):
	data["peer_id"] = peer_id
	socket.get_peer(1).put_packet(JSON.stringify(data).to_utf8_buffer())
	logger.info("Sent to server: %s" % data)
#endregion
