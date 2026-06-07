class_name VRSpace
extends Node

signal center_player(offset: Vector3)
signal restart_game()
signal back_to_home()

@export var origin: XROrigin3D
@export var camera: XRCamera3D
@export var pause_menu: Control
@export var overlay_mesh: OverlayMesh
@export var menu_function: XRToolsFunctionMenu
@export var reset_area: Area3D

@export_category("Gameover")
@export var vr_screen: XRToolsViewport2DIn3D
@export var gameover_scene: PackedScene

var was_paused := false

func _ready() -> void:
	menu_function.menu_opened.connect(_connect_menu)
	menu_function.menu_closed.connect(_on_menu_closed)
	reset_area.body_entered.connect(func(_b): reset_space())
	vr_screen.hide()
	pause_menu.hide()

func _connect_menu(menu: VRMenuPanel):
	menu.quit_pressed.connect(func(): back_to_home.emit())
	menu.reset_space_pressed.connect(func(): reset_space())
	menu.settings_pressed.connect(_on_settings_pressed)
	overlay_mesh.show_overlay()
	pause_menu.show()
	was_paused = get_tree().paused
	get_tree().paused = true

func reset_space(offset: Vector3 = Vector3.ZERO):
	offset.y = 0
	center_player.emit(offset)

func _on_menu_closed():
	pause_menu.hide()
	get_tree().paused = was_paused
	if not get_tree().paused:
		overlay_mesh.hide_overlay()

# deprecated
func gameover(msg: String):
	var screen = show_screen(gameover_scene) as GameoverPanel
	screen.back_to_menu.connect(func(): back_to_home.emit())
	screen.restart_game.connect(func(): restart_game.emit())
	screen.set_title(msg)

	var rankings = StatsManager.get_rankings()
	screen.set_rankings(rankings)

func show_screen(screen: PackedScene):
	#overlay_mesh.show_overlay()
	vr_screen.set_scene(screen)
	vr_screen.show()
	return vr_screen.get_scene_instance()

func hide_screen():
	#overlay_mesh.hide_overlay()
	vr_screen.hide()

func activate():
	origin.current = true
	camera.current = true

func _on_settings_pressed():
	pass  # Settings handled via debug keys (Shift++ / Shift+-)
