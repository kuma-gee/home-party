@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsFunctionMenu
extends XRToolsHandAimOffset

signal menu_opened(menu: VRMenuPanel)
signal menu_closed

@export var menu_button_action: String = "by_button"
@export var menu_scene: PackedScene
@export var menu_offset: Vector3 = Vector3(0, 0.05, -0.15)
@export var menu_rotation: Vector3 = Vector3(-45, 0, 0)
@export var menu_scale: float = 0.3
@export var smooth_follow: bool = true
@export var follow_speed: float = 15.0
@export var long_press_duration: float = 0.5
@export var fade_duration: float = 0.15
@export var open_indicator: ColorRect


@onready var _menu_anchor: Node3D = $MenuAnchor

var _is_holding: bool = false:
	set(v):
		_is_holding = v
		open_indicator.visible = v
var _hold_timer: float = 0.0:
	set(v):
		_hold_timer = v
		var mat = open_indicator.material as ShaderMaterial
		mat.set_shader_parameter("fill", v / long_press_duration)

var _menu_enabled: bool = true
var _menu_instance: Node3D = null
var _fade_tween: Tween = null
var _target_transform: Transform3D = Transform3D()
var _world_scale: float = 1.0

func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsFunctionMenu"


func set_menu_enabled(enabled: bool) -> void:
	_menu_enabled = enabled
	if not enabled and _menu_instance:
		close_menu()

func _ready() -> void:
	_is_holding = false
	_hold_timer = 0.0
	
	if Engine.is_editor_hint():
		return
	
	_world_scale = XRServer.world_scale
	
	if _controller:
		_controller.button_pressed.connect(_on_button_pressed)
		_controller.button_released.connect(_on_button_released)


func _process(delta: float) -> void:
	super._process(delta)
	
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	
	var new_world_scale := XRServer.world_scale
	if _world_scale != new_world_scale:
		_world_scale = new_world_scale
		_update_menu_transform()
	
	if _is_holding and not _menu_instance:
		_hold_timer += delta
		if _hold_timer >= long_press_duration:
			_is_holding = false
			_open_menu()

	if _menu_instance and _menu_anchor:
		_update_menu_transform()
		
		if smooth_follow:
			_menu_anchor.transform = _menu_anchor.transform.interpolate_with(
				_target_transform, 
				follow_speed * delta
			)
		else:
			_menu_anchor.transform = _target_transform


func _on_button_pressed(button_name: String) -> void:
	if button_name != menu_button_action or not _menu_enabled:
		return
	
	if _menu_instance:
		close_menu()
	else:
		_is_holding = true
		_hold_timer = 0.0


func _on_button_released(button_name: String) -> void:
	if button_name == menu_button_action:
		_is_holding = false
		_hold_timer = 0.0


func _open_menu() -> void:
	if _menu_instance or not menu_scene:
		return
	
	_menu_instance = menu_scene.instantiate()
	_menu_instance.resume_pressed.connect(func(): close_menu())
	_menu_anchor.add_child(_menu_instance)
	
	_update_menu_transform()
	_menu_anchor.transform = _target_transform
	_menu_instance.scale = Vector3(0.01, 0.01, 0.01)
	
	if _fade_tween:
		_fade_tween.kill()
	
	set_pointer(false)
	_fade_tween = create_tween().set_parallel()
	_fade_tween.set_trans(Tween.TRANS_BACK)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(_menu_instance, "scale", Vector3.ONE * menu_scale, fade_duration)
	
	menu_opened.emit(_menu_instance)

func set_pointer(enabled: bool):
	var pointer = XRTools.find_xr_child(_controller, "*", "XRToolsFunctionPointer", false) as XRToolsFunctionPointer
	if pointer:
		pointer.enabled = enabled

func close_menu() -> void:
	if not _menu_instance:
		return
	
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween().set_parallel()
	_fade_tween.set_trans(Tween.TRANS_BACK)
	_fade_tween.set_ease(Tween.EASE_IN)
	_fade_tween.tween_property(_menu_instance, "scale", Vector3(0.01, 0.01, 0.01), fade_duration)
	_fade_tween.tween_callback(func(): _menu_instance.hide()).set_delay(fade_duration)
	_fade_tween.finished.connect(_on_menu_close_finished)
	
	menu_closed.emit()

func _on_menu_close_finished() -> void:
	if _menu_instance:
		_menu_instance.queue_free()
		_menu_instance = null
	set_pointer(true)


func _update_menu_transform() -> void:
	if not _menu_anchor:
		return
	
	var offset_scaled := menu_offset * _world_scale
	var rotation_rad := Vector3(
		deg_to_rad(menu_rotation.x),
		deg_to_rad(menu_rotation.y),
		deg_to_rad(menu_rotation.z)
	)
	
	_target_transform = Transform3D()
	_target_transform = _target_transform.rotated(Vector3.RIGHT, rotation_rad.x)
	_target_transform = _target_transform.rotated(Vector3.UP, rotation_rad.y)
	_target_transform = _target_transform.rotated(Vector3.FORWARD, rotation_rad.z)
	_target_transform.origin = offset_scaled
