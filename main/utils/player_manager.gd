extends Node

signal clients_changed()

var logger := KumaLog.new("PlayerManager")
var playing_clients: Array[ClientController] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	LobbyServer.player_connected.connect(create_peer)
	LobbyServer.player_disconnected.connect(remove_peer)
	LobbyServer.received_candidate.connect(_on_received_candidate)
	LobbyServer.received_session.connect(_on_received_session)

	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	for device_id in Input.get_connected_joypads():
		register_gamepad(device_id)

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	logger.debug("Joy connection changed: device_id=%d, connected=%s" % [device_id, connected])
	if connected:
		register_gamepad(device_id)
	else:
		unregister_gamepad(device_id)

func _on_received_candidate(client_id: String, mid: String, index: int, sdp: String):
	var player = find_player_by_uuid(client_id)
	if player is GameClient:
		(player as GameClient).add_ice_candidate(mid, index, sdp)
	else:
		logger.warn("Failed to find player with id %s to set ice candidate" % client_id)

func _on_received_session(client_id: String, type: String, sdp: String):
	var player = find_player_by_uuid(client_id)
	if player is GameClient:
		(player as GameClient).set_session(type, sdp)
	else:
		logger.warn("Failed to find player with id %s to set session" % client_id)

func get_player_idx(uuid: String) -> int:
	for i in get_child_count():
		var child = get_child(i)
		if child is ClientController and (child as ClientController).uuid == uuid:
			return i
	return -1

func find_player_by_uuid(uuid: String) -> ClientController:
	for child in get_children():
		if child is ClientController and (child as ClientController).uuid == uuid:
			return child
	return null

func find_player_by_device_id(device_id: int) -> GamepadController:
	for child in get_children():
		var pad = child as GamepadController
		if pad and pad.device_id == device_id:
			return pad
	return null

func start_game():
	playing_clients = []
	for child in get_children():
		if child is ClientController and child.active:
			playing_clients.append(child as ClientController)

func get_players() -> Array[ClientController]:
	return playing_clients

func create_peer(data: Dictionary):
	var peer_id = int(data.get("peer_id", -1))
	if peer_id < 0:
		logger.error("Error: No peer_id in player data")
		return

	var uuid = data.get("client_id", "")
	var existing = find_player_by_uuid(uuid)
	if existing:
		existing.initialize()
	else:
		var player = GameClient.new()
		player.name = "%s" % peer_id
		player.uuid = uuid
		player.data = data
		player.send_candidate.connect(func(mid: String, index: int, sdp: String): LobbyServer.send_candidate(uuid, mid, index, sdp))
		player.send_session.connect(func(type: String, sdp: String): LobbyServer.send_session(uuid, type, sdp))
		add_child(player)
	clients_changed.emit()

func remove_peer(client_id: String):
	var player = find_player_by_uuid(client_id)
	if player is GameClient:
		player.reset()
	else:
		logger.warn("Failed to remove player with id %s" % client_id)
	clients_changed.emit()

func register_gamepad(device_id: int) -> void:
	logger.debug("Gamepad Info: %s" % Input.get_joy_info(device_id))

	var existing = find_player_by_device_id(device_id)
	if existing:
		existing.initialize()
	else:
		var uuid := GamepadController.get_uuid_for_device(device_id)
		var controller := GamepadController.new()
		controller.device_id = device_id
		controller.uuid = uuid
		controller.player_name = "%s" % Input.get_joy_name(device_id)
		add_child(controller)
	clients_changed.emit()

func unregister_gamepad(device_id: int) -> void:
	var player = find_player_by_device_id(device_id)
	if player:
		player.reset()
		clients_changed.emit()
