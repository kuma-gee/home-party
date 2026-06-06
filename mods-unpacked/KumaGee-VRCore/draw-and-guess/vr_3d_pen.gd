@tool
class_name VR3DPen
extends XRToolsPickable

signal stroke_created(stroke: Node3D)
signal color_changed(color: Color)

@export var line_thickness := 0.03
@export var line_color := Color.BLACK
@export var pen_tip: Node3D
@export var pen_tip_area: Area3D
@export var mesh: MeshInstance3D

const CIRCLE_SEGMENTS := 8

var is_drawing := false
var current_stroke: Node3D = null
var current_mesh: ImmediateMesh = null
var current_material: StandardMaterial3D = null
var last_point: Vector3 = Vector3.ZERO
var min_segment_length := 0.005

var stroke_points: PackedVector3Array = []

var strokes_container: Node3D = null

func _ready():
	super._ready()
	if Engine.is_editor_hint():
		return
	_find_strokes_container()
	action_pressed.connect(_on_action_pressed)
	action_released.connect(_on_action_released)
	if pen_tip_area:
		pen_tip_area.area_entered.connect(_on_pen_tip_area_entered)
	change_color(line_color)

func _find_strokes_container():
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "StrokesContainer":
			strokes_container = child
			return
	
	strokes_container = Node3D.new()
	strokes_container.name = "StrokesContainer"
	Staging.add_scene_child(strokes_container)

func change_color(color: Color):
	line_color = color
	var color_mat = StandardMaterial3D.new()
	color_mat.albedo_color = color
	mesh.set_surface_override_material(2, color_mat)
	color_changed.emit(color)

func _on_pen_tip_area_entered(area: Area3D):
	var swatch := area as DrawingColorSwatch
	if swatch:
		change_color(swatch.swatch_color)

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	
	if not is_drawing:
		return
	
	var tip_pos = _get_tip_position()
	if tip_pos == Vector3.ZERO:
		return
	
	if stroke_points.is_empty():
		stroke_points.append(tip_pos)
		last_point = tip_pos
		return
	
	var direction = tip_pos - last_point
	if direction.length() < min_segment_length:
		return
	
	stroke_points.append(tip_pos)
	last_point = tip_pos
	
	_rebuild_mesh()

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
	stroke_points = []
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
			
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p2)
			current_mesh.surface_add_vertex(p3)
			
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p3)
			current_mesh.surface_add_vertex(p4)

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
			
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p3)
			current_mesh.surface_add_vertex(p2)
			
			current_mesh.surface_add_vertex(p1)
			current_mesh.surface_add_vertex(p4)
			current_mesh.surface_add_vertex(p3)

func _rebuild_mesh():
	if not current_mesh or stroke_points.size() < 2:
		return
	
	current_mesh.clear_surfaces()
	current_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_thickness = line_thickness * 0.5
	var local_last_up := Vector3.UP
	var local_last_forward := Vector3.FORWARD
	var local_prev_ring: PackedVector3Array = []
	var has_started := false
	
	for i in range(1, stroke_points.size()):
		var p0 = stroke_points[i - 1]
		var p1 = stroke_points[i]
		var forward = (p1 - p0).normalized()
		if forward.length() < 0.001:
			forward = local_last_forward
		
		local_last_up = _compute_up(forward, local_last_up)
		
		if not has_started:
			_add_start_cap(p0, forward, local_last_up)
			has_started = true
		
		var start_ring = _compute_ring(p0, forward, local_last_up, half_thickness)
		var end_ring = _compute_ring(p1, forward, local_last_up, half_thickness)
		
		if not local_prev_ring.is_empty():
			if (local_last_forward - forward).length() > 0.001:
				_add_ring_fill(local_prev_ring, start_ring)
		
		for j in range(CIRCLE_SEGMENTS):
			var next_j = (j + 1) % CIRCLE_SEGMENTS
			current_mesh.surface_add_vertex(start_ring[j])
			current_mesh.surface_add_vertex(end_ring[next_j])
			current_mesh.surface_add_vertex(end_ring[j])
			current_mesh.surface_add_vertex(start_ring[j])
			current_mesh.surface_add_vertex(start_ring[next_j])
			current_mesh.surface_add_vertex(end_ring[next_j])
		
		local_prev_ring = end_ring
		local_last_forward = forward
	
	if has_started:
		_add_end_cap(stroke_points[-1], local_last_forward, local_last_up)
	
	current_mesh.surface_end()

func _end_stroke():
	if not is_drawing:
		return
	
	_rebuild_mesh()
	
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
	
	for i in range(CIRCLE_SEGMENTS):
		var next_i = (i + 1) % CIRCLE_SEGMENTS
		
		current_mesh.surface_add_vertex(old_ring[i])
		current_mesh.surface_add_vertex(new_ring[next_i])
		current_mesh.surface_add_vertex(new_ring[i])
		
		current_mesh.surface_add_vertex(old_ring[i])
		current_mesh.surface_add_vertex(old_ring[next_i])
		current_mesh.surface_add_vertex(new_ring[next_i])

func set_drawing_enabled(enabled: bool) -> void:
	if not enabled and is_drawing:
		_end_stroke()
	is_drawing = enabled
