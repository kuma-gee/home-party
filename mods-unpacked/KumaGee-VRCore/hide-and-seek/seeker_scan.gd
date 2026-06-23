class_name SeekerScan
extends Node

## VR Seeker scan mechanic. On right grip press, fires a directional cone that
## reveals footprint markers at each in-cone hider's position from ~3 seconds
## ago, with an arrow indicating the direction they were heading.

@export var cone_angle_deg: float = 60.0
@export var range: float = 10.0
@export var cooldown_duration: float = 8.0
@export var marker_duration: float = 2.0

var function_pointer: XRToolsFunctionPointer
var controller: XRController3D
var hiders_getter: Callable
var marker_parent: Node3D
var cooldown_time: float = 0.0

var _cooldown: float = 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown < 0.0:
			_cooldown = 0.0
	cooldown_time = _cooldown


func set_cooldown(seconds: float) -> void:
	_cooldown = maxf(_cooldown, seconds)


func is_on_cooldown() -> bool:
	return _cooldown > 0.0


func setup(p_controller: XRController3D, p_function_pointer: XRToolsFunctionPointer, p_hiders_getter: Callable, p_marker_parent: Node3D) -> void:
	controller = p_controller
	function_pointer = p_function_pointer
	hiders_getter = p_hiders_getter
	marker_parent = p_marker_parent
	if controller:
		controller.button_pressed.connect(_on_button_pressed)


func _on_button_pressed(button: String) -> void:
	if button != "grip_click":
		return
	if is_on_cooldown() or not function_pointer:
		return
	_perform_scan()
	set_cooldown(cooldown_duration)


func _perform_scan() -> void:
	if not hiders_getter.is_valid():
		return

	var origin: Vector3 = function_pointer.global_position
	var forward: Vector3 = -function_pointer.global_transform.basis.z
	var half_cone: float = deg_to_rad(cone_angle_deg * 0.5)

	var hiders: Array = hiders_getter.call()
	for hider in hiders:
		if not hider is HiderCharacter or not is_instance_valid(hider):
			continue
		if (hider as HiderCharacter).is_found:
			continue

		var to_hider: Vector3 = hider.global_position - origin
		to_hider.y = 0.0
		var dist: float = to_hider.length()
		if dist > range or dist < 0.01:
			continue
		if forward.angle_to(to_hider.normalized()) > half_cone:
			continue

		_spawn_footprint(hider as HiderCharacter)


func _spawn_footprint(hider: HiderCharacter) -> void:
	var samples: Array[Vector3] = hider.get_trail_samples()
	if samples.is_empty():
		return

	var oldest: Vector3 = samples[0]
	oldest.y = 0.05
	var next_pos: Vector3 = samples[1] if samples.size() > 1 else samples[0]
	var dir: Vector3 = next_pos - samples[0]
	dir.y = 0.0

	var parent: Node3D = marker_parent if marker_parent else get_parent()
	if not parent:
		return

	var marker := Node3D.new()
	marker.global_position = oldest
	parent.add_child(marker)

	var footprint := Label3D.new()
	footprint.text = "👣"
	footprint.pixel_size = 0.05
	footprint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	footprint.modulate = Color(1.0, 0.9, 0.3, 1.0)
	marker.add_child(footprint)

	var arrow: Label3D = null
	if dir.length() > 0.05:
		arrow = Label3D.new()
		arrow.text = "➤"
		arrow.pixel_size = 0.06
		arrow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		arrow.modulate = Color(1.0, 0.6, 0.1, 1.0)
		arrow.rotation.y = atan2(dir.x, dir.z)
		marker.add_child(arrow)

	# Hold visible briefly, then fade out the labels and free the marker.
	var tw := create_tween()
	tw.tween_interval(marker_duration * 0.5)
	tw.parallel().tween_property(footprint, "modulate:a", 0.0, marker_duration * 0.5)
	if arrow:
		tw.parallel().tween_property(arrow, "modulate:a", 0.0, marker_duration * 0.5)
	tw.finished.connect(func() -> void:
		if is_instance_valid(marker):
			marker.queue_free()
	)
