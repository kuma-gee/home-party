@tool
class_name EraserTool
extends XRToolsPickable

signal stroke_erased(stroke: DrawingStroke)

@export var eraser_tip: Node3D
@export var eraser_mesh: MeshInstance3D

var is_erasing := false
var has_erased_this_press := false

var _active_material: StandardMaterial3D = null
var _idle_material: StandardMaterial3D = null

func _ready():
	super._ready()
	if Engine.is_editor_hint():
		return
	action_pressed.connect(_on_action_pressed)
	action_released.connect(_on_action_released)
	_build_materials()
	_set_active_visual(false)

func _build_materials():
	_idle_material = StandardMaterial3D.new()
	_idle_material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
	_idle_material.metallic = 0.2
	_idle_material.roughness = 0.6

	_active_material = StandardMaterial3D.new()
	_active_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
	_active_material.metallic = 0.1
	_active_material.roughness = 0.3
	_active_material.emission_enabled = true
	_active_material.emission = Color(1.0, 0.1, 0.1, 1.0)
	_active_material.emission_energy_multiplier = 2.0

func _on_action_pressed(_pickable):
	is_erasing = true
	has_erased_this_press = false
	_set_active_visual(true)

func _on_action_released(_pickable):
	is_erasing = false
	_set_active_visual(false)

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return

	if not is_erasing or has_erased_this_press:
		return

	_try_erase()

func _try_erase():
	var tip_pos = eraser_tip.global_position if is_instance_valid(eraser_tip) else global_position
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
			has_erased_this_press = true
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
	var mat = _active_material if active else _idle_material
	if mat:
		eraser_mesh.material_override = mat

func _find_strokes_container() -> Node3D:
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "StrokesContainer":
			return child
	return null
