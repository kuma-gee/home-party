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
@export var direct_movement: XRToolsMovementProvider
@export var teleport_function: XRToolsFunctionTeleport
@export var vignette: XRToolsVignette
@export var player_body: XRToolsPlayerBody
@export var debug_camera: Camera3D
@export var show_pause_overlay := true

const SETTINGS_PANEL_DISTANCE := 0.8
const SEATED_HEIGHT_OVERRIDE := 1.0
const DESKTOP_FALLBACK_PATH := ^"SubViewport/XRPlayer/DesktopVRFallback"

var was_paused := false
var _pause_active := false
var _settings_panel_instance: SettingsPanel = null
var _locomotion_enabled := true
var _settings_panel_y_offset := 0.0
var _previous_camera: Camera3D = null

@onready var _desktop_vr_fallback: DesktopVRFallback = get_node_or_null(DESKTOP_FALLBACK_PATH)

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
	_settings_panel_instance.player_height_changed.connect(_on_player_height_changed)

	UserSettings.setting_changed.connect(_on_setting_changed)
	_apply_movement_mode()
	_apply_vignette_enabled()
	_apply_seated_mode()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_debug_camera_input(event):
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_toggle_debug_camera()
		get_viewport().set_input_as_handled()
		return

	if not (event is InputEventKey):
		return

	if not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return

	if settings_viewport.visible:
		_on_menu_closed(true)
	else:
		_open_settings_menu()

	get_viewport().set_input_as_handled()


func _handle_debug_camera_input(event: InputEvent) -> bool:
	if not debug_camera.current or _desktop_vr_fallback == null:
		return false

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_desktop_vr_fallback.capture_mouse()
			return true
		return false

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_desktop_vr_fallback.apply_mouse_motion(event.relative)
		return true

	return false


func _process(_delta: float) -> void:
	if not settings_viewport.visible:
		return

	var panel_position := settings_viewport.global_position
	panel_position.y = camera.global_position.y + _settings_panel_y_offset
	settings_viewport.global_position = panel_position

func _on_setting_changed(section: String, key: String) -> void:
	if section != "comfort":
		return
	if key == "movement_mode":
		_apply_movement_mode()
	elif key == "vignette_enabled":
		_apply_vignette_enabled()
	elif key == "seated_mode":
		_apply_seated_mode()

func _apply_vignette_enabled() -> void:
	var enabled := UserSettings.get_vignette_enabled()
	vignette.auto_adjust = enabled
	if not enabled:
		vignette.set_radius(1.0)

## Seated mode locks the player's collider to a fixed low height so real-world
## floor-height tracking doesn't fight a seated player's actual HMD height.
func _apply_seated_mode() -> void:
	if UserSettings.get_seated_mode():
		player_body.override_player_height(&"comfort_seated", SEATED_HEIGHT_OVERRIDE)
	else:
		player_body.override_player_height(&"comfort_seated")

func _connect_menu(menu: VRMenuPanel):
	menu.quit_pressed.connect(func(): back_to_home.emit())
	menu.reset_space_pressed.connect(func(): reset_space())
	menu.settings_pressed.connect(_on_settings_pressed)
	
	if settings_viewport.visible:
		settings_viewport.hide()
		return
	
	_show_pause_menu()


func _show_pause_menu() -> void:
	if _pause_active:
		return

	_pause_active = true
	was_paused = get_tree().paused
	if show_pause_overlay:
		overlay_mesh.show_overlay()
		pause_menu.show()
		get_tree().paused = true

func reset_space(offset: Vector3 = Vector3.ZERO):
	offset.y = 0
	center_player.emit(offset)

func _on_menu_closed(from_settings := false):
	if settings_viewport.visible and not from_settings:
		return
	
	_pause_active = false
	if show_pause_overlay:
		pause_menu.hide()
		get_tree().paused = was_paused
		if not get_tree().paused:
			overlay_mesh.hide_overlay()
	settings_viewport.hide()

func activate():
	origin.current = true
	camera.current = true


func _toggle_debug_camera() -> void:
	if debug_camera == null:
		push_warning("DebugVRView camera missing; debug camera toggle disabled")
		return

	if debug_camera.current:
		var restore_camera := _previous_camera if is_instance_valid(_previous_camera) else _find_desktop_camera()
		if restore_camera != null:
			restore_camera.make_current()
		_previous_camera = null
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	var current_camera := get_viewport().get_camera_3d()
	if current_camera != null and current_camera != debug_camera and current_camera != camera:
		_previous_camera = current_camera
	else:
		_previous_camera = _find_desktop_camera()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	debug_camera.make_current()


func _find_desktop_camera() -> Camera3D:
	var scene := get_tree().current_scene
	if scene == null:
		return null

	for child in scene.get_children():
		if child is Camera3D and child != debug_camera and child != camera:
			return child

	return null

## Toggle player-driven movement (walking + teleport) for games that
## don't want free player locomotion (e.g. fixed-position defense games).
func set_locomotion_enabled(value: bool) -> void:
	_locomotion_enabled = value
	_apply_movement_mode()

## Movement mode is exclusive: only smooth (direct) OR teleport is active,
## per the player's comfort setting.
func _apply_movement_mode() -> void:
	if not _locomotion_enabled:
		direct_movement.enabled = false
		teleport_function.enabled = false
		return
	var mode := UserSettings.get_movement_mode()
	direct_movement.enabled = mode == UserSettings.MovementMode.SMOOTH
	teleport_function.enabled = mode == UserSettings.MovementMode.TELEPORT

func _on_settings_pressed():
	_open_settings_menu()


func _open_settings_menu() -> void:
	_show_pause_menu()
	_place_in_front_of_player(settings_viewport, SETTINGS_PANEL_DISTANCE)
	_settings_panel_y_offset = settings_viewport.global_position.y - camera.global_position.y
	settings_viewport.show()
	menu_function.close_menu()

func _place_in_front_of_player(node: Node3D, distance: float) -> void:
	var cam_transform := camera.global_transform
	var forward := -cam_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	node.global_position = cam_transform.origin + forward * distance
	node.look_at(cam_transform.origin, Vector3.UP)
	node.rotate_object_local(Vector3.UP, PI)

func _on_settings_back_pressed():
	_on_menu_closed(true)


func _on_player_height_changed(_new_height: float) -> void:
	player_body.calibrate_player_height()
