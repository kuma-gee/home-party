class_name VRSpace
extends Node

signal center_player(offset: Vector3)
signal restart_game()
signal back_to_home()

@export var origin: XROrigin3D
@export var initial_transform: Node3D
@export var camera: XRCamera3D
@export var pause_menu: Control
@export var overlay_mesh: OverlayMesh
@export var menu_function: XRToolsFunctionMenu
@export var reset_area: Area3D
@export var settings_viewport: XRToolsViewport2DIn3D

var was_paused := false
var _settings_panel_instance: SettingsPanel = null

func _ready() -> void:
	menu_function.menu_opened.connect(_connect_menu)
	menu_function.menu_closed.connect(_on_menu_closed)
	reset_area.body_entered.connect(func(_b): reset_space())
	pause_menu.hide()
	
	if initial_transform:
		origin.transform = initial_transform.transform
	
	settings_viewport.hide()
	_settings_panel_instance = settings_viewport.get_scene_instance()
	_settings_panel_instance.back_pressed.connect(_on_settings_back_pressed)

func _connect_menu(menu: VRMenuPanel):
	menu.quit_pressed.connect(func(): back_to_home.emit())
	menu.reset_space_pressed.connect(func(): reset_space())
	menu.settings_pressed.connect(_on_settings_pressed)
	
	if settings_viewport.visible:
		settings_viewport.hide()
		return
	
	overlay_mesh.show_overlay()
	pause_menu.show()
	was_paused = get_tree().paused
	get_tree().paused = true

func reset_space(offset: Vector3 = Vector3.ZERO):
	offset.y = 0
	center_player.emit(offset)

func _on_menu_closed(from_settings := false):
	if settings_viewport.visible and not from_settings:
		return
	
	pause_menu.hide()
	get_tree().paused = was_paused
	if not get_tree().paused:
		overlay_mesh.hide_overlay()
	settings_viewport.hide()

func activate():
	origin.current = true
	camera.current = true

func _on_settings_pressed():
	settings_viewport.show()
	menu_function.close_menu()

func _on_settings_back_pressed():
	_on_menu_closed(true)
