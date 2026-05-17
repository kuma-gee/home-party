class_name VRSpace
extends Node

signal restart_game()
signal back_to_home()

@export var origin: XROrigin3D
@export var camera: XRCamera3D
@export var pause_menu: Control
@export var overlay_mesh: OverlayMesh
@export var menu_function: XRToolsFunctionMenu

@export_category("Gameover")
@export var vr_screen: XRToolsViewport2DIn3D
@export var desktop_screen: Node3D
@export var gameover_scene: PackedScene

var was_paused := false

func _ready() -> void:
	menu_function.menu_opened.connect(_connect_menu)
	menu_function.menu_closed.connect(_on_menu_closed)
	vr_screen.hide()
	desktop_screen.hide()
	pause_menu.hide()

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
	var screen = show_screen(gameover_scene, true) as GameoverPanel
	screen.back_to_menu.connect(func(): back_to_home.emit())
	screen.restart_game.connect(func(): restart_game.emit())
	screen.set_title(msg)

func show_screen(screen: PackedScene, show_for_desktop = false):
	overlay_mesh.show_overlay()
	was_paused = get_tree().paused
	get_tree().paused = true
	vr_screen.set_scene(screen)
	vr_screen.show()
	if show_for_desktop:
		desktop_screen.show()
	return vr_screen.get_scene_instance()

func hide_screen():
	get_tree().paused = false
	overlay_mesh.hide_overlay()
	vr_screen.hide()
	desktop_screen.hide()

func activate():
	origin.current = true
	camera.current = true
