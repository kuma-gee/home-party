class_name SettingsPanel
extends Control

signal back_pressed
signal player_height_changed(new_height: float)
signal tab_selected(tab: int)
signal xr_settings_changed

const KEYBOARD_TAB_CHANGE_PREVIOUS := -1
const KEYBOARD_TAB_CHANGE_NEXT := 1

@onready var _master_slider: HSlider = %MasterSlider
@onready var _master_value_label: Label = %MasterValue
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _sfx_value_label: Label = %SFXValue
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value_label: Label = %MusicValue
@onready var _antialiasing_toggle: CheckBox = %AntiAliasingToggle
@onready var _msaa_option: OptionButton = %MSAAOption
@onready var _shadow_quality_option: OptionButton = %ShadowQualityOption
@onready var _vsync_toggle: CheckBox = %VSyncToggle
@onready var _smooth_movement_button: CheckBox = %SmoothMovementButton
@onready var _teleport_movement_button: CheckBox = %TeleportMovementButton
@onready var _vignette_toggle: CheckBox = %VignetteToggle
@onready var _snap_turn_toggle: CheckBox = %SnapTurnToggle
@onready var _player_height_slider: HSlider = %PlayerHeightSlider
@onready var _player_height_value_label: Label = %PlayerHeightValue
@onready var _seated_mode_toggle: CheckBox = %SeatedModeToggle
@onready var _back_button: Button = %BackButton
@onready var _tab_container: TabContainer = $VBoxContainer/TabContainer

var _syncing_from_settings := false
var _syncing_tab := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_sync_from_settings()

	# Connect UI signals → UserSettings
	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_antialiasing_toggle.toggled.connect(_on_antialiasing_toggled)
	_msaa_option.item_selected.connect(_on_msaa_selected)
	_shadow_quality_option.item_selected.connect(_on_shadow_quality_selected)
	_vsync_toggle.toggled.connect(_on_vsync_toggled)
	_smooth_movement_button.toggled.connect(_on_smooth_movement_toggled)
	_teleport_movement_button.toggled.connect(_on_teleport_movement_toggled)
	_vignette_toggle.toggled.connect(_on_vignette_toggled)
	_snap_turn_toggle.toggled.connect(_on_snap_turn_toggled)
	_player_height_slider.value_changed.connect(_on_player_height_value_changed)
	_player_height_slider.drag_ended.connect(_on_player_height_drag_ended)
	_seated_mode_toggle.toggled.connect(_on_seated_mode_toggled)
	_back_button.pressed.connect(back_pressed.emit)
	_tab_container.tab_changed.connect(_on_tab_changed)
	visibility_changed.connect(_on_visibility_changed)
	UserSettings.setting_changed.connect(_on_setting_changed)

	if visible:
		_focus_first_control(true)


func _sync_from_settings() -> void:
	_syncing_from_settings = true
	_master_slider.value = UserSettings.get_master_volume()
	_sfx_slider.value = UserSettings.get_sfx_volume()
	_music_slider.value = UserSettings.get_music_volume()
	_antialiasing_toggle.button_pressed = UserSettings.get_antialiasing()
	_msaa_option.selected = UserSettings.get_msaa_level()
	_shadow_quality_option.selected = UserSettings.get_shadow_quality()
	_vsync_toggle.button_pressed = UserSettings.get_vsync()
	if UserSettings.get_movement_mode() == UserSettings.MovementMode.TELEPORT:
		_teleport_movement_button.button_pressed = true
	else:
		_smooth_movement_button.button_pressed = true
	_vignette_toggle.button_pressed = UserSettings.get_vignette_enabled()
	_snap_turn_toggle.button_pressed = XRToolsUserSettings.snap_turning
	_player_height_slider.value = XRToolsUserSettings.player_height
	_seated_mode_toggle.button_pressed = UserSettings.get_seated_mode()
	_update_seated_mode_label(_seated_mode_toggle.button_pressed)

	# Update value labels
	_update_master_label(_master_slider.value)
	_update_sfx_label(_sfx_slider.value)
	_update_music_label(_music_slider.value)
	_update_player_height_label(_player_height_slider.value)
	_syncing_from_settings = false


func refresh_from_settings() -> void:
	_sync_from_settings()


func _on_setting_changed(_section: String, _key: String) -> void:
	if not _syncing_from_settings:
		_sync_from_settings()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	if event.ctrl_pressed and event.keycode == KEY_TAB:
		var direction := KEYBOARD_TAB_CHANGE_PREVIOUS if event.shift_pressed else KEYBOARD_TAB_CHANGE_NEXT
		_change_tab(direction)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_TAB:
		_move_focus(-1 if event.shift_pressed else 1)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_ESCAPE:
		back_pressed.emit()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------------------
# Slider handlers
# ------------------------------------------------------------------------------

func _on_master_changed(value: float) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_master_volume(value)
	_update_master_label(value)


func _update_master_label(value: float) -> void:
	_master_value_label.text = "%d%%" % (value * 100)


func _on_sfx_changed(value: float) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_sfx_volume(value)
	_update_sfx_label(value)


func _update_sfx_label(value: float) -> void:
	_sfx_value_label.text = "%d%%" % (value * 100)


func _on_music_changed(value: float) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_music_volume(value)
	_update_music_label(value)


func _update_music_label(value: float) -> void:
	_music_value_label.text = "%d%%" % (value * 100)


func _on_antialiasing_toggled(enabled: bool) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_antialiasing(enabled)


func _on_msaa_selected(index: int) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_msaa_level(index)


func _on_shadow_quality_selected(index: int) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_shadow_quality(index)


func _on_vsync_toggled(enabled: bool) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_vsync(enabled)


func _on_smooth_movement_toggled(pressed: bool) -> void:
	if _syncing_from_settings:
		return
	if pressed:
		UserSettings.set_movement_mode(UserSettings.MovementMode.SMOOTH)


func _on_teleport_movement_toggled(pressed: bool) -> void:
	if _syncing_from_settings:
		return
	if pressed:
		UserSettings.set_movement_mode(UserSettings.MovementMode.TELEPORT)


func _on_vignette_toggled(enabled: bool) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_vignette_enabled(enabled)


func _on_snap_turn_toggled(enabled: bool) -> void:
	if _syncing_from_settings:
		return
	XRToolsUserSettings.snap_turning = enabled
	XRToolsUserSettings.save()
	xr_settings_changed.emit()


func _on_player_height_value_changed(value: float) -> void:
	if _syncing_from_settings:
		return
	_update_player_height_label(value)


func _on_player_height_drag_ended(value_changed: bool) -> void:
	if _syncing_from_settings:
		return
	if not value_changed:
		return

	var value := _player_height_slider.value
	XRToolsUserSettings.player_height = value
	XRToolsUserSettings.save()
	xr_settings_changed.emit()
	player_height_changed.emit(value)


func _update_player_height_label(value: float) -> void:
	_player_height_value_label.text = "%.2fm" % value


func _on_seated_mode_toggled(enabled: bool) -> void:
	if _syncing_from_settings:
		return
	UserSettings.set_seated_mode(enabled)
	_update_seated_mode_label(enabled)


func _update_seated_mode_label(enabled: bool) -> void:
	_seated_mode_toggle.text = "On" if enabled else "Off"


func _on_visibility_changed() -> void:
	if visible:
		_sync_from_settings()
		call_deferred("_focus_first_control", true)


func _on_tab_changed(_tab: int) -> void:
	if not _syncing_tab:
		tab_selected.emit(_tab)
	if visible:
		call_deferred("_focus_first_control", true)


func set_current_tab(tab: int) -> void:
	if _tab_container.current_tab == tab:
		return

	_syncing_tab = true
	_tab_container.current_tab = clampi(tab, 0, _tab_container.get_tab_count() - 1)
	_syncing_tab = false


func get_current_tab() -> int:
	return _tab_container.current_tab


func _change_tab(direction: int) -> void:
	var tab_count := _tab_container.get_tab_count()
	if tab_count <= 0:
		return

	var next_tab := posmod(_tab_container.current_tab + direction, tab_count)
	_tab_container.current_tab = next_tab


func _move_focus(direction: int) -> void:
	var focusable_controls := _get_focusable_controls()
	if focusable_controls.is_empty():
		return

	var focused_control := get_viewport().gui_get_focus_owner()
	var focused_index := focusable_controls.find(focused_control)
	if focused_index == -1:
		focusable_controls[0].grab_focus()
		return

	var next_index := posmod(focused_index + direction, focusable_controls.size())
	focusable_controls[next_index].grab_focus()


func _focus_first_control(force: bool = false) -> void:
	var focusable_controls := _get_focusable_controls()
	if focusable_controls.is_empty():
		return

	var focused_control := get_viewport().gui_get_focus_owner()
	if not force and focused_control in focusable_controls:
		return

	focusable_controls[0].grab_focus()


func _get_focusable_controls() -> Array[Control]:
	var focusable_controls: Array[Control] = []
	_collect_focusable_controls(_tab_container.get_current_tab_control(), focusable_controls)
	if _back_button.visible:
		focusable_controls.append(_back_button)
	return focusable_controls


func _collect_focusable_controls(node: Node, focusable_controls: Array[Control]) -> void:
	if node == null:
		return

	if node is Control:
		var control := node as Control
		if control.visible and control.focus_mode != Control.FOCUS_NONE:
			focusable_controls.append(control)

	for child in node.get_children():
		_collect_focusable_controls(child, focusable_controls)
