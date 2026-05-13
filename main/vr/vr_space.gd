class_name VRSpace
extends Node

signal back_to_home()

@export var origin: XROrigin3D
@export var camera: XRCamera3D
@export var menu_function: XRToolsFunctionMenu
@export var pause_menu: Control

func _ready() -> void:
	menu_function.menu_opened.connect(_connect_menu)
	menu_function.menu_closed.connect(func(): pause_menu.hide())
	pause_menu.hide()

func _connect_menu(menu: VRMenuPanel):
	menu.quit_pressed.connect(func(): back_to_home.emit())
	pause_menu.show()

func activate():
	origin.current = true
	camera.current = true
