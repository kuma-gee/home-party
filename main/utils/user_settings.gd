extends Node

signal setting_changed(section: String, key: String)

const CONFIG_PATH := "user://settings.cfg"

# Audio
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0
var _music_volume: float = 1.0

# Graphics
var _render_scale: float = 1.0
var _antialiasing: bool = true

# Comfort
enum MovementMode { SMOOTH, TELEPORT }
var _movement_mode: MovementMode = MovementMode.SMOOTH
var _vignette_enabled: bool = false
var _seated_mode: bool = false


func _ready() -> void:
	load_settings()


# ------------------------------------------------------------------------------
# Audio
# ------------------------------------------------------------------------------

func get_master_volume() -> float:
	return _master_volume


func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_save()
	setting_changed.emit("audio", "master_volume")
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(_master_volume)
	)


func get_sfx_volume() -> float:
	return _sfx_volume


func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_save()
	setting_changed.emit("audio", "sfx_volume")
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(_sfx_volume)
	)


func get_music_volume() -> float:
	return _music_volume


func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_save()
	setting_changed.emit("audio", "music_volume")
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(_music_volume)
	)


# ------------------------------------------------------------------------------
# Graphics
# ------------------------------------------------------------------------------

func get_render_scale() -> float:
	return _render_scale


func set_render_scale(value: float) -> void:
	_render_scale = clampf(value, 0.5, 2.0)
	_save()
	setting_changed.emit("graphics", "render_scale")
	get_viewport().scaling_3d_scale = _render_scale


func get_antialiasing() -> bool:
	return _antialiasing


func set_antialiasing(value: bool) -> void:
	_antialiasing = value
	_save()
	setting_changed.emit("graphics", "antialiasing")
	if _antialiasing:
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED


# ------------------------------------------------------------------------------
# Comfort
# ------------------------------------------------------------------------------

func get_movement_mode() -> MovementMode:
	return _movement_mode


func set_movement_mode(value: MovementMode) -> void:
	_movement_mode = value
	_save()
	setting_changed.emit("comfort", "movement_mode")


func get_vignette_enabled() -> bool:
	return _vignette_enabled


func set_vignette_enabled(value: bool) -> void:
	_vignette_enabled = value
	_save()
	setting_changed.emit("comfort", "vignette_enabled")


func get_seated_mode() -> bool:
	return _seated_mode


func set_seated_mode(value: bool) -> void:
	_seated_mode = value
	_save()
	setting_changed.emit("comfort", "seated_mode")


# ------------------------------------------------------------------------------
# Persistence
# ------------------------------------------------------------------------------

func _save() -> void:
	var config := ConfigFile.new()

	config.set_value("audio", "master_volume", _master_volume)
	config.set_value("audio", "sfx_volume", _sfx_volume)
	config.set_value("audio", "music_volume", _music_volume)
	config.set_value("graphics", "render_scale", _render_scale)
	config.set_value("graphics", "antialiasing", _antialiasing)
	config.set_value("comfort", "movement_mode", _movement_mode)
	config.set_value("comfort", "vignette_enabled", _vignette_enabled)
	config.set_value("comfort", "seated_mode", _seated_mode)

	var result := config.save(CONFIG_PATH)
	if result != OK:
		push_error("UserSettings: Failed to save config: ", result)


func load_settings() -> void:
	var config := ConfigFile.new()
	var result := config.load(CONFIG_PATH)
	if result != OK:
		_apply_all()
		return

	_master_volume = clampf(config.get_value("audio", "master_volume", 1.0), 0.0, 1.0)
	_sfx_volume = clampf(config.get_value("audio", "sfx_volume", 1.0), 0.0, 1.0)
	_music_volume = clampf(config.get_value("audio", "music_volume", 1.0), 0.0, 1.0)
	_render_scale = clampf(config.get_value("graphics", "render_scale", 1.0), 0.5, 2.0)
	_antialiasing = config.get_value("graphics", "antialiasing", true)
	_movement_mode = config.get_value("comfort", "movement_mode", MovementMode.SMOOTH) as MovementMode
	_vignette_enabled = config.get_value("comfort", "vignette_enabled", false)
	_seated_mode = config.get_value("comfort", "seated_mode", false)

	_apply_all()


func _apply_all() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(_master_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(_sfx_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(_music_volume)
	)
	get_viewport().scaling_3d_scale = _render_scale
	if _antialiasing:
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
