class_name LobbyClient
extends Node

signal connected_to_server()

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
		if data.msg == LobbyServer.Message.Id:
			_on_id_message(data)

func _on_id_message(data: Dictionary):
	peer_id = data.id
	connected_to_server.emit()
	logger.info("Received assigned ID from server: %d" % peer_id)

#region actions
func join_server(ip = "127.0.0.1"):
	if is_socket_connected():
		logger.warn("Already connected to server.")
		return
	
	socket.create_client("ws://%s:%s" % [ip, LobbyServer.PORT])
	logger.info("Connecting to signaling server at %s:%d" % [ip, LobbyServer.PORT])

func send_user_data(data: Dictionary):
	if not is_socket_connected():
		logger.warn("Cannot send user data, not connected to server.")
		return
	
	data["msg"] = LobbyServer.Message.Id
	_send_to_server(data)

func _send_to_server(data: Dictionary):
	data["peer_id"] = peer_id
	socket.get_peer(1).put_packet(JSON.stringify(data).to_utf8_buffer())
	logger.debug("Sent user data to server: %s" % data)
#endregion
