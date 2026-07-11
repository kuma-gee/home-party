class_name DrawingClearSwatch
extends Area3D

signal cleared()

@export var HOLD_DURATION := 2.0
@export var progress_ring: ColorRect

var _hold_progress := 0.0
var _is_held := false
var _shader_material: ShaderMaterial

func _ready():
	collision_layer = 0
	collision_layer = 1 << 9

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	cleared.connect(_clear_all_strokes)
	
	_shader_material = progress_ring.material
	_update_progress_visual()

func _on_area_entered(_area: Area3D):
	_is_held = true
	_hold_progress = 0.0

func _on_area_exited(_area: Area3D):
	_is_held = false
	_hold_progress = 0.0
	_update_progress_visual()

func _process(delta: float):
	if not _is_held:
		return
	_hold_progress += delta
	_update_progress_visual()
	if _hold_progress >= HOLD_DURATION:
		cleared.emit()
		_is_held = false
		_hold_progress = 0.0
		_update_progress_visual()

func _update_progress_visual():
	var t := clampf(_hold_progress / HOLD_DURATION, 0.0, 1.0)
	if _shader_material:
		_shader_material.set_shader_parameter("fill", t)

func _clear_all_strokes():
	var root = get_tree().get_first_node_in_group(VR3DPen.STROKES_GROUP)
	if root:
		for stroke in root.get_children():
			stroke.queue_free()
