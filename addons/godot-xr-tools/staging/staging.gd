class_name XRToolsStaging
extends Node3D

signal scene_exiting(scene, user_data)
signal switching_to_loading_scene()
signal scene_loaded(scene, user_data)
signal scene_visible(scene, user_data)

signal xr_started
signal xr_ended

@export_file('*.tscn') var main_scene : String

@export var desktop_camera: Camera3D
@export var xr_origin : XROrigin3D
@export var xr_camera : XRCamera3D
@export var loading: LoadingScreen
@export var prompt_for_continue : bool = true

@export_category("Fade")
@export var fade: XRToolsFade
@export var fade_time := 1.0
@export var desktop_fade: Control

@onready var start_xr: XRToolsStartXR = $StartXR
@onready var scene: Node3D = $Scene

var current_scene : XRToolsSceneBase
var current_scene_path : String
var _tween : Tween

func _ready():
	if Engine.is_editor_hint():
		return

	if xr_camera:
		loading.set_camera(xr_camera)

	load_scene(main_scene)

var escape_timer := 0.0

func _process(delta: float) -> void:
	if Input.is_key_pressed(Key.KEY_ESCAPE):
		escape_timer += delta
		if escape_timer >= 3.0:
			_on_exit_to_main_menu()
	else:
		escape_timer = 0.0


# Verifies our staging has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Report main scene not specified
	if main_scene == "":
		warnings.append("No main scene selected")

	# Report main scene invalid
	if !FileAccess.file_exists(main_scene):
		warnings.append("Main scene doesn't exist")

	# Return warnings
	return warnings


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsStaging"

func create_sfx_at(sfx_scene: PackedScene, pos: Vector3):
	var sfx = sfx_scene.instantiate()
	sfx.position = pos
	add_scene_child(sfx)

func add_scene_child(node: Node):
	scene.add_child(node)

func load_scene(p_scene_path : String, user_data = null) -> void:
	if Engine.is_editor_hint() or !xr_origin or !xr_camera:
		return

	ResourceLoader.load_threaded_request(p_scene_path)

	if current_scene:
		await fade_black()
		clean_up_previous_scene(user_data)

	await get_tree().create_timer(1.0).timeout
	if should_show_loading(p_scene_path):
		enable_loading_screen()

	if loading.visible:
		await fade_visible()

		var res = await wait_for_scene_load(p_scene_path)
		if res != ResourceLoader.THREAD_LOAD_LOADED:
			push_error("Error ", res, " loading resource ", p_scene_path)
			# Halt if running in the debugger
			# gdlint:ignore=expression-not-assigned
			breakpoint
			get_tree().quit(1)

		await loading.show_ready(prompt_for_continue)
		if prompt_for_continue:
			await loading.continue_pressed

		await fade_black()
		disable_loading_screen()

	await get_tree().create_timer(0.5).timeout
	await setup_new_scene(p_scene_path, user_data)
	await fade_visible()
	current_scene.scene_visible(user_data)
	scene_visible.emit(current_scene, user_data)

func setup_new_scene(p_scene_path : String, user_data):
	var new_scene : PackedScene = ResourceLoader.load_threaded_get(p_scene_path)

	# Setup our new scene
	current_scene = new_scene.instantiate()
	current_scene_path = p_scene_path
	scene.add_child(current_scene)
	_add_signals(current_scene)
	BGMManager.start(current_scene.bgm_audio)

	await get_tree().physics_frame
	get_tree().paused = false
	current_scene.xr_player.activate()
	current_scene.scene_loaded(user_data)
	scene_loaded.emit(current_scene, user_data)

	# We create a small delay here to give tracking some time to update our nodes...
	await get_tree().create_timer(0.2).timeout

func clean_up_previous_scene(user_data):
	if not current_scene: return
	current_scene.scene_pre_exiting(user_data)
	_remove_signals(current_scene)
	BGMManager.stop()

	# Now we remove our scene
	emit_signal("scene_exiting", current_scene, user_data)
	current_scene.scene_exiting(user_data)
	for child in scene.get_children():
		child.queue_free()
	current_scene = null

func should_show_loading(p_scene_path : String) -> bool:
	return prompt_for_continue or ResourceLoader.load_threaded_get_status(p_scene_path) != ResourceLoader.THREAD_LOAD_LOADED

func enable_loading_screen():
	start_xr._initialize()
	desktop_camera.current = true
	xr_origin.set_process_internal(true)
	xr_origin.current = true
	xr_camera.current = true
	loading.set_loading_state(true)
	loading.follow_camera = true
	loading.visible = true
	switching_to_loading_scene.emit()

func disable_loading_screen():
	desktop_camera.current = false
	loading.follow_camera = false
	loading.visible = false
	xr_origin.set_process_internal(false)

func wait_for_scene_load(p_scene_path : String) -> ResourceLoader.ThreadLoadStatus:
	var res : ResourceLoader.ThreadLoadStatus
	while true:
		var progress := []
		res = ResourceLoader.load_threaded_get_status(p_scene_path, progress)
		if res != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			break

		loading.progress = progress[0]
		await get_tree().create_timer(0.1).timeout

	return res

func fade_black():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(set_fade, 0.0, 1.0, fade_time)
	await _tween.finished

func fade_visible():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(set_fade, 1.0, 0.0, fade_time)
	await _tween.finished

func set_fade(p_value : float):
	XRToolsFade.fade_all(Color(0, 0, 0, p_value))
	desktop_fade.modulate.a = p_value


func _add_signals(p_scene : XRToolsSceneBase):
	p_scene.connect("request_exit_to_main_menu", _on_exit_to_main_menu)
	p_scene.connect("request_load_scene", _on_load_scene)
	p_scene.connect("request_reset_scene", _on_reset_scene)
	p_scene.connect("request_quit", _on_quit)
	p_scene.xr_player.back_to_home.connect(_on_exit_to_main_menu)
	p_scene.xr_player.restart_game.connect(_on_reset_scene)


func _remove_signals(p_scene : XRToolsSceneBase):
	p_scene.disconnect("request_exit_to_main_menu", _on_exit_to_main_menu)
	p_scene.disconnect("request_load_scene", _on_load_scene)
	p_scene.disconnect("request_reset_scene", _on_reset_scene)
	p_scene.disconnect("request_quit", _on_quit)
	p_scene.xr_player.back_to_home.disconnect(_on_exit_to_main_menu)
	p_scene.xr_player.restart_game.disconnect(_on_reset_scene)


func _on_exit_to_main_menu():
	load_scene(main_scene)


func _on_load_scene(p_scene_path : String, user_data):
	load_scene(p_scene_path, user_data)


func _on_reset_scene():
	load_scene(current_scene_path)


func _on_quit():
	$StartXR.end_xr()


func _on_StartXR_xr_started():
	emit_signal("xr_started")


func _on_StartXR_xr_ended():
	emit_signal("xr_ended")
