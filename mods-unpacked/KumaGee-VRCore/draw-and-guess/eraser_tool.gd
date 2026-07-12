@tool
class_name EraserTool
extends XRToolsPickable

signal stroke_erased(stroke: DrawingStroke)

#@export var snap_zone: XRToolsSnapZone
@export var eraser_mesh: CSGSphere3D
@export var active_color := Color(1.0, 0.2, 0.2, 1.0)
@export var normal_color := Color(0.7, 0.7, 0.7, 1.0)

var is_erasing := false

func _ready():
	super._ready()
	if Engine.is_editor_hint():
		return
	
	#dropped.connect(func(_p): snap_zone.pick_up_object(self))
	#snap_zone.has_dropped.connect(func():
		#if not is_picked_up():
			#snap_zone.pick_up_object(self)
	#)
	
	action_pressed.connect(_on_action_pressed)
	action_released.connect(_on_action_released)
	_set_active_visual(false)

func _on_action_pressed(_pickable):
	is_erasing = true
	_set_active_visual(true)

func _on_action_released(_pickable):
	is_erasing = false
	_set_active_visual(false)

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return

	if not is_erasing:
		return

	_try_erase()

func _try_erase():
	var tip_pos = global_position
	var container = _find_strokes_container()
	if not container:
		return

	for child in container.get_children():
		var stroke := child as DrawingStroke
		if not stroke:
			continue
		if _is_touching_stroke(tip_pos, stroke):
			stroke.queue_free()
			stroke_erased.emit(stroke)
			return

func _is_touching_stroke(tip_pos: Vector3, stroke: DrawingStroke) -> bool:
	var threshold = max(stroke.line_thickness * 1.5, 0.02)
	var threshold_sq = threshold * threshold
	for point in stroke.stroke_points:
		if tip_pos.distance_squared_to(point) < threshold_sq:
			return true
	return false

func _set_active_visual(active: bool):
	if not is_instance_valid(eraser_mesh):
		return
	
	var mat = eraser_mesh.material as StandardMaterial3D
	mat.albedo_color = active_color if active else normal_color

func _find_strokes_container() -> Node3D:
	return get_tree().get_first_node_in_group(VR3DPen.STROKES_GROUP)
