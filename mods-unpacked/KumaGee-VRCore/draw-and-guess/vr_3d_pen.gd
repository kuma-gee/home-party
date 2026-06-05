@tool
class_name VR3DPen
extends XRToolsPickable

signal stroke_created(stroke: Node3D)

@export var line_thickness := 0.03
@export var line_color := Color.BLACK
@export var pen_tip: Node3D

var is_drawing := false
var current_stroke: Node3D = null
var current_mesh: ImmediateMesh = null
var current_material: StandardMaterial3D = null
var last_point: Vector3 = Vector3.ZERO
var min_segment_length := 0.005

var strokes_container: Node3D = null

func _ready():
	super._ready()
	if Engine.is_editor_hint():
		return
	_find_strokes_container()
	action_pressed.connect(_on_action_pressed)
	action_released.connect(_on_action_released)

func _find_strokes_container():
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "StrokesContainer":
			strokes_container = child
			return
	
	strokes_container = Node3D.new()
	strokes_container.name = "StrokesContainer"
	Staging.add_scene_child(strokes_container)

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	
	if not is_drawing:
		return
	
	var tip_pos = _get_tip_position()
	if tip_pos == Vector3.ZERO:
		return
	
	var direction = tip_pos - last_point
	if direction.length() < min_segment_length:
		return
	
	_add_segment_point(tip_pos)
	last_point = tip_pos

func _get_tip_position() -> Vector3:
	if is_instance_valid(pen_tip):
		return pen_tip.global_position
	return global_position

func _on_action_pressed(_pickable):
	_start_stroke()

func _on_action_released(_pickable):
	_end_stroke()

func _start_stroke():
	if is_drawing:
		return
	
	is_drawing = true
	current_stroke = Node3D.new()
	current_stroke.name = "Stroke"
	
	var mesh_instance = MeshInstance3D.new()
	current_mesh = ImmediateMesh.new()
	current_material = StandardMaterial3D.new()
	current_material.albedo_color = line_color
	current_material.vertex_color_use_as_albedo = true
	
	mesh_instance.mesh = current_mesh
	mesh_instance.material_override = current_material
	current_stroke.add_child(mesh_instance)
	
	strokes_container.add_child(current_stroke)
	
	last_point = _get_tip_position()
	current_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	stroke_created.emit(current_stroke)

func _add_segment_point(point: Vector3):
	var half_thickness = line_thickness * 0.5
	
	var up = Vector3.UP
	var forward = (point - last_point).normalized()
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	
	var right = forward.cross(up).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
		up = forward.cross(right).normalized()
	else:
		up = right.cross(forward).normalized()
	
	right *= half_thickness
	up *= half_thickness
	
	current_mesh.surface_add_vertex(last_point + up + right)
	current_mesh.surface_add_vertex(last_point + up - right)
	current_mesh.surface_add_vertex(point + up + right)
	current_mesh.surface_add_vertex(point + up - right)

func _end_stroke():
	if not is_drawing:
		return
	
	if current_mesh:
		current_mesh.surface_end()
	
	is_drawing = false
	current_stroke = null
	current_mesh = null
	current_material = null

func set_drawing_enabled(enabled: bool) -> void:
	if not enabled and is_drawing:
		_end_stroke()
	is_drawing = enabled
