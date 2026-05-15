class_name VRSpace
extends Node

signal restart_game()
signal back_to_home()

@export var origin: XROrigin3D
@export var camera: XRCamera3D
@export var pause_menu: Control
@export var overlay_mesh: OverlayMesh
@export var menu_function: XRToolsFunctionMenu
@export var gameover_vr_screen: XRToolsViewport2DIn3D
@export var gameover_desktop_screen: Node3D

var was_paused := false

func _ready() -> void:
	menu_function.menu_opened.connect(_connect_menu)
	menu_function.menu_closed.connect(_on_menu_closed)
	
	_setup_gameover_screen()
	pause_menu.hide()

func _setup_gameover_screen():
	var screen = gameover_vr_screen.get_scene_instance() as GameoverPanel
	screen.back_to_menu.connect(func(): back_to_home.emit())
	screen.restart_game.connect(func(): restart_game.emit())
	gameover_vr_screen.hide()
	gameover_desktop_screen.hide()

func _connect_menu(menu: VRMenuPanel):
	menu.quit_pressed.connect(func(): back_to_home.emit())
	overlay_mesh.show_overlay()
	pause_menu.show()
	was_paused = get_tree().paused
	get_tree().paused = true

func _on_menu_closed():
	pause_menu.hide()
	overlay_mesh.hide_overlay()
	get_tree().paused = was_paused

func gameover(msg: String):
	overlay_mesh.show_overlay()
	get_tree().paused = true
	
	var screen = gameover_vr_screen.get_scene_instance() as GameoverPanel
	screen.set_title(msg)
	gameover_vr_screen.show()
	gameover_desktop_screen.show()

func activate():
	origin.current = true
	camera.current = true
