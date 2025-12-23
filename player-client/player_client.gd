extends Control

@export var joystick: VirtualJoystick

@export_category("UI Nodes")
@export var connection_ui: Control
@export var lobby_ui: Control
@export var message_label: Label

@export_category("Connection UI")
@export var connect_btn: Button
@export var name_line: LineEdit
@export var server_line: LineEdit

@onready var client: LobbyClient = $Client
@onready var game_client: GameClient = $GameClient
@onready var menus = [connection_ui, lobby_ui]

var was_pressed = false

func _ready() -> void:
	connect_btn.disabled = true
	connect_btn.pressed.connect(func():
		message_label.text = "Connecting..."
		connect_btn.disabled = true
		
		var err = client.join_server(server_line.text)
		message_label.text = "Status: %s" % err
		connect_btn.disabled = false
	)
	server_line.text_changed.connect(func(x): connect_btn.disabled = x == "")
	name_line.text_changed.connect(func(x): connect_btn.disabled = x == "")
	client.connected_to_server.connect(_on_connected_to_server)
	client.received_candidate.connect(func(mid: String, index: int, sdp: String):
		game_client.add_ice_candidate(mid, index, sdp)
	)
	client.received_session.connect(func(type: String, sdp: String):
		game_client.set_session(type, sdp)
	)
	game_client.send_candidate.connect(func(mid: String, index: int, sdp: String):
		client.send_game_client_ice_candidate(mid, index, sdp)
	)
	game_client.send_session.connect(func(type: String, sdp: String):
		client.send_game_client_session(type, sdp)
	)

	var ip = _parse_ip_from_query_param()
	if ip != "":
		server_line.text = ip

	_change_menu(connection_ui)

func _parse_ip_from_query_param():
	if OS.has_feature('web'):
		var map_data = JavaScriptBridge.eval('''
			let params = new URL(document.location).searchParams;
			return params.get("ip");
		''')
		if map_data:
			return map_data

	return ""	

func _update_move_state(input: String, current: bool, new: bool) -> bool:
	if current == new:
		return current
	
	game_client.send_input(input, new)
	return new

func _process(_delta: float) -> void:
	if joystick.is_pressed:
		game_client.send_move("move", joystick.output)
	elif was_pressed:
		game_client.send_move("move", Vector2.ZERO)

	was_pressed = joystick.is_pressed

func _change_menu(target_menu: Control) -> void:
	for menu in menus:
		menu.visible = menu == target_menu

func _on_connected_to_server() -> void:
	client.send_user_data({ "name": name_line.text })
	_change_menu(lobby_ui)
	message_label.text = "Connected to server."

	await get_tree().create_timer(1.0).timeout
	game_client.create_offer()
