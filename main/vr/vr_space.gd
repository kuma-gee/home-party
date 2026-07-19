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
@export var desktop_settings_panel: SettingsPanel
@export var desktop_feedback_panel: Control
@export var show_pause_overlay := true

const SETTINGS_PANEL_DISTANCE := 0.8
const SEATED_HEIGHT_OVERRIDE := 1.0
const DESKTOP_FALLBACK_PATH := ^"SubViewport/XRPlayer/DesktopVRFallback"
const DESKTOP_MENU_SCENE := preload("res://main/vr/vr_menu_panel_ui.tscn")

var was_paused := false
var _pause_active := false
var _settings_panel_instance: SettingsPanel = null
var _locomotion_enabled := true
var _settings_panel_y_offset := 0.0
var _previous_camera: Camera3D = null
var _desktop_canvas: CanvasLayer = null
var _desktop_canvas_was_visible := true
var _pause_canvas: CanvasLayer = null
var _pause_canvas_was_visible := true
var _desktop_menu_instance: Control = null
var _desktop_menu_overlay: ColorRect = null

@onready var _desktop_vr_fallback: DesktopVRFallback = get_node_or_null(DESKTOP_FALLBACK_PATH)

func _ready() -> void:
	_desktop_canvas = _get_base_game_desktop_canvas()
	_pause_canvas = _get_pause_canvas()
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
	_settings_panel_instance.tab_selected.connect(_on_vr_settings_tab_selected)
	_settings_panel_instance.xr_settings_changed.connect(_on_xr_settings_changed)
	if desktop_settings_panel != null:
		desktop_settings_panel.hide()
		desktop_settings_panel.back_pressed.connect(_on_settings_back_pressed)
		desktop_settings_panel.player_height_changed.connect(_on_player_height_changed)
		desktop_settings_panel.tab_selected.connect(_on_desktop_settings_tab_selected)
		desktop_settings_panel.xr_settings_changed.connect(_on_xr_settings_changed)
	if desktop_feedback_panel != null:
		desktop_feedback_panel.hide()

	UserSettings.setting_changed.connect(_on_setting_changed)
	_apply_movement_mode()
	_apply_vignette_enabled()
	_apply_seated_mode()


#func _input(event: InputEvent) -> void:
	#if not _is_escape_key(event):
		#return

	#if debug_camera != null and debug_camera.current and settings_viewport.visible:
		#_on_menu_closed(true)
		#get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_debug_camera_input(event):
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.ctrl_pressed and key.alt_pressed and not key.shift_pressed and key.keycode == KEY_F1:
			_toggle_debug_camera()
			get_viewport().set_input_as_handled()
			return

	if not _is_escape_key(event) or not event.is_pressed():
		return
		
	if settings_viewport.visible:
		_on_menu_closed(true)
	elif menu_function.is_menu_open():
		menu_function.close_menu()
	else:
		_open_menu()

	get_viewport().set_input_as_handled()


func _is_escape_key(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE


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
	_show_desktop_menu()
	
	if settings_viewport.visible:
		settings_viewport.hide()
		_hide_desktop_settings_panel()
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
	_hide_desktop_settings_panel()
	_hide_desktop_menu()


func _open_menu() -> void:
	_show_pause_menu()
	menu_function.open_menu()

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
		_set_desktop_canvas_enabled(true)
		_set_pause_canvas_enabled(true)
		return

	var current_camera := get_viewport().get_camera_3d()
	if current_camera != null and current_camera != debug_camera and current_camera != camera:
		_previous_camera = current_camera
	else:
		_previous_camera = _find_desktop_camera()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_desktop_canvas_enabled(false)
	_set_pause_canvas_enabled(false)
	debug_camera.make_current()


func _find_desktop_camera() -> Camera3D:
	var scene := get_tree().current_scene
	if scene == null:
		return null

	for child in scene.get_children():
		if child is Camera3D and child != debug_camera and child != camera:
			return child

	return null


func _get_base_game_desktop_canvas() -> CanvasLayer:
	var base_game := get_parent() as BaseGame
	if base_game == null:
		return null

	return base_game.desktop_canvas


func _set_desktop_canvas_enabled(enabled: bool) -> void:
	if _desktop_canvas == null:
		_desktop_canvas = _get_base_game_desktop_canvas()
	if _desktop_canvas == null:
		return

	if enabled:
		_desktop_canvas.visible = _desktop_canvas_was_visible
		return

	_desktop_canvas_was_visible = _desktop_canvas.visible
	_desktop_canvas.hide()


func _get_pause_canvas() -> CanvasLayer:
	if pause_menu == null:
		return null

	return pause_menu.get_parent() as CanvasLayer


func _set_pause_canvas_enabled(enabled: bool) -> void:
	if _pause_canvas == null:
		_pause_canvas = _get_pause_canvas()
	if _pause_canvas == null:
		return

	if enabled:
		_pause_canvas.visible = _pause_canvas_was_visible
		return

	_pause_canvas_was_visible = _pause_canvas.visible
	_pause_canvas.hide()

## Toggle player-driven movement (walking + teleport) for games that
## don't want free player locomotion (e.g. fixed-position defense games).
func set_locomotion_enabled(value: bool) -> void:
	_locomotion_enabled = value
	if _desktop_vr_fallback != null:
		_desktop_vr_fallback.locomotion_enabled = value
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
	_settings_panel_instance.refresh_from_settings()
	_place_in_front_of_player(settings_viewport, SETTINGS_PANEL_DISTANCE)
	_settings_panel_y_offset = settings_viewport.global_position.y - camera.global_position.y
	settings_viewport.show()
	if pause_menu != null:
		_show_desktop_menu_overlay(pause_menu.get_parent())
	_show_desktop_settings_panel()
	_hide_desktop_menu_panel()
	menu_function.close_menu()


func _show_desktop_menu() -> void:
	if pause_menu == null:
		return

	if _desktop_menu_instance != null:
		return

	var menu_parent := pause_menu.get_parent()
	if menu_parent == null:
		return

	_desktop_menu_instance = DESKTOP_MENU_SCENE.instantiate() as Control
	_show_desktop_menu_overlay(menu_parent)
	menu_parent.add_child(_desktop_menu_instance)
	_connect_desktop_menu_button("MarginContainer/VBoxContainer/ResumeButton", func(): menu_function.close_menu())
	_setup_desktop_feedback_button("MarginContainer/VBoxContainer/ResetSpaceButton")
	_connect_desktop_menu_button("MarginContainer/VBoxContainer/SettingsButton", _on_settings_pressed)
	_connect_desktop_menu_button("MarginContainer/VBoxContainer/HomeButton", func(): back_to_home.emit())


func _show_desktop_menu_overlay(menu_parent: Node) -> void:
	if menu_parent == null:
		return

	if _desktop_menu_overlay != null:
		return

	if pause_menu != null and pause_menu.visible:
		return

	_desktop_menu_overlay = ColorRect.new()
	_desktop_menu_overlay.name = "DesktopMenuOverlay"
	_desktop_menu_overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	_desktop_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_desktop_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_parent.add_child(_desktop_menu_overlay)
	if desktop_settings_panel != null and desktop_settings_panel.get_parent() == menu_parent:
		menu_parent.move_child(_desktop_menu_overlay, desktop_settings_panel.get_index())


func _connect_desktop_menu_button(path: NodePath, callback: Callable) -> void:
	if _desktop_menu_instance == null:
		return

	var button := _desktop_menu_instance.get_node_or_null(path) as Button
	if button != null:
		button.pressed.connect(callback)


func _setup_desktop_feedback_button(path: NodePath) -> void:
	if _desktop_menu_instance == null:
		return

	var button := _desktop_menu_instance.get_node_or_null(path) as Button
	if button == null:
		return

	button.text = "Feedback"
	button.pressed.connect(_open_desktop_feedback_form)


func _open_desktop_feedback_form() -> void:
	if desktop_feedback_panel == null:
		return
	if desktop_feedback_panel.visible:
		return
	if pause_menu == null:
		return

	var menu_parent := pause_menu.get_parent()
	if menu_parent == null:
		return

	_hide_desktop_menu_panel()
	_show_desktop_menu_overlay(menu_parent)
	desktop_feedback_panel.show()
	if desktop_feedback_panel.get_parent() == menu_parent:
		menu_parent.move_child(desktop_feedback_panel, menu_parent.get_child_count() - 1)


func _hide_desktop_menu() -> void:
	if desktop_feedback_panel != null:
		desktop_feedback_panel.hide()

	if _desktop_menu_overlay != null:
		_desktop_menu_overlay.queue_free()
		_desktop_menu_overlay = null

	_hide_desktop_menu_panel()


func _hide_desktop_menu_panel() -> void:
	if _desktop_menu_instance != null:
		_desktop_menu_instance.queue_free()
		_desktop_menu_instance = null

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


func close_settings_menu() -> void:
	_on_menu_closed(true)


func _show_desktop_settings_panel() -> void:
	if desktop_settings_panel == null:
		return

	desktop_settings_panel.set_current_tab(_settings_panel_instance.get_current_tab())
	desktop_settings_panel.show()


func _hide_desktop_settings_panel() -> void:
	if desktop_settings_panel != null:
		desktop_settings_panel.hide()


func _on_vr_settings_tab_selected(tab: int) -> void:
	if desktop_settings_panel != null:
		desktop_settings_panel.set_current_tab(tab)


func _on_desktop_settings_tab_selected(tab: int) -> void:
	if _settings_panel_instance != null:
		_settings_panel_instance.set_current_tab(tab)


func _on_xr_settings_changed() -> void:
	if _settings_panel_instance != null:
		_settings_panel_instance.refresh_from_settings()
	if desktop_settings_panel != null:
		desktop_settings_panel.refresh_from_settings()


func _on_player_height_changed(_new_height: float) -> void:
	player_body.calibrate_player_height()
