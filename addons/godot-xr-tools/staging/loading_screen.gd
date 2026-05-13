@tool
class_name LoadingScreen
extends CameraFollow3D

signal continue_pressed


@export var splash_screen : Texture2D: set = set_splash_screen

@export var loading_label: Label3D
@export var ready_label: Label3D

@export var press_to_continue: Node3D
@export var hold_button: XRToolsHoldButton

@onready var spinner: MeshInstance3D = $Spinner

var _background_material : StandardMaterial3D

func _ready():
	_background_material = $Background.get_surface_override_material(0)
	set_loading_state(true)
	_update_splash_screen()
	super._ready()


func set_splash_screen(p_splash_screen : Texture2D) -> void:
	splash_screen = p_splash_screen
	_update_splash_screen()

func _update_splash_screen() -> void:
	if _background_material:
		_background_material.albedo_texture = splash_screen


func set_loading_state(loading = false) -> void:
	if is_inside_tree():
		spinner.visible = loading
		loading_label.visible = loading
		ready_label.visible = false
		press_to_continue.visible = !loading
		hold_button.enabled = !loading

func _on_HoldButton_pressed():
	continue_pressed.emit()

func show_ready(wait_continue: bool, time = 1.0):
	if wait_continue:
		set_loading_state(false)
		return

	var mat = spinner.get_surface_override_material(0) as ShaderMaterial
	var tw = create_tween().set_parallel()\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)

	tw.tween_property(mat, "shader_parameter/fade_amount", 0.0, time)
	tw.tween_property(mat, "shader_parameter/ring_width", 0.4, time)

	loading_label.visible = false
	ready_label.visible = true
	await tw.finished
	mat.set_shader_parameter("speed", 0.0)
