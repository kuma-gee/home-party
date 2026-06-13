extends Node

signal clients_changed()

var logger := KumaLog.new("PlayerManager")
var playing_clients: Array[ClientController] = []
var _assigned_indices := {}       # uuid -> int
var _freed_indices: Array[int] = []

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
	return _assigned_indices.get(uuid, -1)

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

func get_active_players() -> Array[ClientController]:
	var active_players: Array[ClientController] = []
	for player in get_children():
		if player is ClientController and player.active:
			active_players.append(player)
	return active_players

func _assign_index(uuid: String) -> int:
	if _assigned_indices.has(uuid):
		return _assigned_indices[uuid]
	if _freed_indices.size() > 0:
		_freed_indices.sort()
		var idx = _freed_indices.pop_front()
		_assigned_indices[uuid] = idx
		return idx
	var idx = _assigned_indices.size()
	_assigned_indices[uuid] = idx
	return idx

func _free_index(uuid: String):
	var idx = _assigned_indices.get(uuid, -1)
	if idx >= 0:
		_freed_indices.append(idx)
		_assigned_indices.erase(uuid)

func create_peer(data: Dictionary):
	var peer_id = int(data.get("peer_id", -1))
	if peer_id < 0:
		logger.error("Error: No peer_id in player data")
		return

	var uuid = data.get("client_id", "")
	var existing = find_player_by_uuid(uuid)
	if existing:
		existing.initialize()
		logger.info("Initializing existing game client: %s" % existing.get_display_data())
	else:
		var player = GameClient.new()
		player.name = "%s" % peer_id
		player.uuid = uuid
		player.data = data
		player.send_candidate.connect(func(mid: String, index: int, sdp: String): LobbyServer.send_candidate(uuid, mid, index, sdp))
		player.send_session.connect(func(type: String, sdp: String): LobbyServer.send_session(uuid, type, sdp))
		add_child(player)
		logger.info("Creating game client: %s" % player.get_display_data())

	_assign_index(uuid)
	clients_changed.emit()

func remove_peer(client_id: String):
	var player = find_player_by_uuid(client_id)
	if player is GameClient:
		player.reset()
		_free_index(client_id)
	else:
		logger.warn("Failed to remove player with id %s" % client_id)
	clients_changed.emit()

func register_gamepad(device_id: int) -> void:
	var info = Input.get_joy_info(device_id)
	logger.debug("Gamepad Info: %s" % info)
	
	var n = info.raw_name.to_lower()
	if "wacom" in n or "intuos" in n:
		return

	var existing = find_player_by_device_id(device_id)
	if existing:
		existing.initialize()
		_assign_index(existing.uuid)
		logger.info("Initializing existing gamepad controller: %s" % existing.get_display_data())
	else:
		var uuid := GamepadController.get_uuid_for_device(device_id)
		var controller := GamepadController.new()
		controller.device_id = device_id
		controller.uuid = uuid
		controller.player_name = "%s" % Input.get_joy_name(device_id)
		add_child(controller)
		_assign_index(uuid)
		logger.info("Creating gamepad controller: %s" % controller.get_display_data())
	clients_changed.emit()

func register_fake_gamepad(uuid: String, player_idx: int = -1) -> void:
	var controller := GamepadController.new()
	controller.device_id = -1
	controller.uuid = uuid
	controller.player_name = "Tester"
	add_child(controller)
	if player_idx >= 0:
		_assigned_indices[uuid] = player_idx
	else:
		_assign_index(uuid)
	clients_changed.emit()


func remove_all_players() -> void:
	for child in get_children():
		if child is ClientController and child.active:
			remove_peer(child.uuid)

func unregister_gamepad(device_id: int) -> void:
	var player = find_player_by_device_id(device_id)
	if player:
		_free_index(player.uuid)
		player.reset()
		clients_changed.emit()
