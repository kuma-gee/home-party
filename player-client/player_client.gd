extends Control

@export_category("UI Nodes")
@export var connection_ui: Control
@export var lobby_ui: Control

@export_category("Connection UI")
@export var connect_btn: Button
@export var name_line: LineEdit

@onready var client: LobbyClient = $Client
@onready var menus = [connection_ui, lobby_ui]

func _ready() -> void:
	connect_btn.disabled = true
	connect_btn.pressed.connect(func(): client.join_server())
	name_line.text_changed.connect(func(): connect_btn.disabled = name_line.text == "")
	client.connected_to_server.connect(_on_connected_to_server)

	_change_menu(connection_ui)

func _change_menu(target_menu: Control) -> void:
	for menu in menus:
		menu.visible = menu == target_menu

func _on_connected_to_server() -> void:
	client.send_user_data({ "name": name_line.text })
	_change_menu(lobby_ui)
