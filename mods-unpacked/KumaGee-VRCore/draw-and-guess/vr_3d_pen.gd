@tool
class_name VR3DPen
extends XRToolsPickable

signal stroke_created(stroke: Node3D)

@export var line_thickness := 0.03
@export var line_color := Color.BLACK
@export var pen_tip: Node3D

const CIRCLE_SEGMENTS := 8

var is_drawing := false
var current_stroke: Node3D = null
var current_mesh: ImmediateMesh = null
var current_material: StandardMaterial3D = null
var last_point: Vector3 = Vector3.ZERO
var last_forward: Vector3 = Vector3.FORWARD
var start_forward: Vector3 = Vector3.FORWARD
var min_segment_length := 0.005

var strokes_container: Node3D = null

var last_up: Vector3 = Vector3.UP
var prev_ring: PackedVector3Array = []

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
	current_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mesh_instance.mesh = current_mesh
	mesh_instance.material_override = current_material
	current_stroke.add_child(mesh_instance)
	
	strokes_container.add_child(current_stroke)
	
	last_point = _get_tip_position()
	start_forward = Vector3.ZERO
	last_forward = Vector3.FORWARD
	last_up = Vector3.UP
	prev_ring = []
	
	stroke_created.emit(current_stroke)

func _add_start_cap(center: Vector3, forward: Vector3, up: Vector3):
	if not current_mesh: return
	
	var half_thickness = line_thickness * 0.5
	var right = forward.cross(up).normalized()
	
	var angle_step = TAU / CIRCLE_SEGMENTS
	var ring_count := 4
	
	for ring in range(ring_count):
		var t1 = float(ring) / float(ring_count)
		var t2 = float(ring + 1) / float(ring_count)
		
		var angle1 = t1 * PI * 0.5
		var angle2 = t2 * PI * 0.5
		
		var r1 = sin(angle1)
		var z1 = cos(angle1)
		var r2 = sin(angle2)
		var z2 = cos(angle2)
		
		for i in range(CIRCLE_SEGMENTS):
			var a1 = angle_step * i
			var a2 = angle_step * ((i + 1) % CIRCLE_SEGMENTS)
			
			var p1 = center + (right * cos(a1) + up * sin(a1)) * half_thickness * r1 - forward * half_thickness * z1
			var p2 = center + (right * cos(a2) + up * sin(a2)) * half_thickness * r1 - forward * half_thickness * z1
			var p3 = center + (right * cos(a2) + up * sin(a2)) * half_thickness * r2 - forward * half_thickness * z2
			var p4 = center + (right * cos(a1) + up * sin(a1)) * half_thickness * r2 - forward * half_thickness * z2
			
			current_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p2)
			current_mesh.surface_add_vertex(p3)
			
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p3)
			current_mesh.surface_add_vertex(p4)
			current_mesh.surface_end()

func _add_end_cap(center: Vector3, forward: Vector3, up: Vector3):
	if not current_mesh: return
	
	var half_thickness = line_thickness * 0.5
	var right = forward.cross(up).normalized()
	
	var angle_step = TAU / CIRCLE_SEGMENTS
	var ring_count := 4
	
	for ring in range(ring_count):
		var t1 = float(ring) / float(ring_count)
		var t2 = float(ring + 1) / float(ring_count)
		
		var angle1 = t1 * PI * 0.5
		var angle2 = t2 * PI * 0.5
		
		var r1 = sin(angle1)
		var z1 = cos(angle1)
		var r2 = sin(angle2)
		var z2 = cos(angle2)
		
		for i in range(CIRCLE_SEGMENTS):
			var a1 = angle_step * i
			var a2 = angle_step * ((i + 1) % CIRCLE_SEGMENTS)
			
			var p1 = center + (right * cos(a1) + up * sin(a1)) * half_thickness * r1 + forward * half_thickness * z1
			var p2 = center + (right * cos(a2) + up * sin(a2)) * half_thickness * r1 + forward * half_thickness * z1
			var p3 = center + (right * cos(a2) + up * sin(a2)) * half_thickness * r2 + forward * half_thickness * z2
			var p4 = center + (right * cos(a1) + up * sin(a1)) * half_thickness * r2 + forward * half_thickness * z2
			
			current_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p3)
			current_mesh.surface_add_vertex(p2)
			
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p4)
			current_mesh.surface_add_vertex(p3)
			current_mesh.surface_end()

func _add_segment_point(point: Vector3):
	if not current_mesh: return
	
	var half_thickness = line_thickness * 0.5
	var forward = (point - last_point).normalized()
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	
	last_up = _compute_up(forward, last_up)
	
	if start_forward == Vector3.ZERO:
		start_forward = forward
		_add_start_cap(last_point, forward, last_up)
	
	var start_ring = _compute_ring(last_point, forward, last_up, half_thickness)
	var end_ring = _compute_ring(point, forward, last_up, half_thickness)
	
	if not prev_ring.is_empty():
		if (last_forward - forward).length() > 0.001:
			_add_ring_fill(prev_ring, start_ring)
	
	current_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(CIRCLE_SEGMENTS):
		var next_i = (i + 1) % CIRCLE_SEGMENTS
		
		current_mesh.surface_add_vertex(start_ring[i])
		current_mesh.surface_add_vertex(end_ring[next_i])
		current_mesh.surface_add_vertex(end_ring[i])
		
		current_mesh.surface_add_vertex(start_ring[i])
		current_mesh.surface_add_vertex(start_ring[next_i])
		current_mesh.surface_add_vertex(end_ring[next_i])
	current_mesh.surface_end()
	
	prev_ring = end_ring
	last_forward = forward

func _end_stroke():
	if not is_drawing:
		return
	
	if start_forward != Vector3.ZERO:
		_add_end_cap(last_point, last_forward, last_up)
	
	is_drawing = false
	current_stroke = null
	current_mesh = null
	current_material = null

func _compute_up(forward: Vector3, reference_up: Vector3) -> Vector3:
	var right = forward.cross(reference_up)
	if right.length() < 0.001:
		if abs(forward.x) < 0.9:
			right = forward.cross(Vector3.RIGHT)
		else:
			right = forward.cross(Vector3.UP)
	right = right.normalized()
	return right.cross(forward).normalized()

func _compute_ring(center: Vector3, forward: Vector3, up: Vector3, radius: float) -> PackedVector3Array:
	var ring: PackedVector3Array = []
	var right = forward.cross(up).normalized()
	var local_up = right.cross(forward).normalized()
	var angle_step = TAU / CIRCLE_SEGMENTS
	for i in range(CIRCLE_SEGMENTS):
		var angle = angle_step * i
		var circle_vec = right * cos(angle) + local_up * sin(angle)
		ring.append(center + circle_vec * radius)
	return ring

func _add_ring_fill(old_ring: PackedVector3Array, new_ring: PackedVector3Array):
	if not current_mesh: return
	if old_ring.size() != new_ring.size(): return
	
	current_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(CIRCLE_SEGMENTS):
		var next_i = (i + 1) % CIRCLE_SEGMENTS
		
		current_mesh.surface_add_vertex(old_ring[i])
		current_mesh.surface_add_vertex(new_ring[next_i])
		current_mesh.surface_add_vertex(new_ring[i])
		
		current_mesh.surface_add_vertex(old_ring[i])
		current_mesh.surface_add_vertex(old_ring[next_i])
		current_mesh.surface_add_vertex(new_ring[next_i])
	current_mesh.surface_end()

func set_drawing_enabled(enabled: bool) -> void:
	if not enabled and is_drawing:
		_end_stroke()
	is_drawing = enabled
