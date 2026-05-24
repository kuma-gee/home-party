@tool
class_name Bow
extends XRToolsPickable

@export var arrow_speed := 20.0
@export var max_draw := 0.5
@export var min_draw := 0.05

@export_category("Arrow")
@export var arrow_mesh_rest_offset := -0.35
@export var arrow_pivot: Node3D
@export var arrow_mesh: Node3D
@export var arrow_snap: XRToolsSnapZone

@export_category("String")
@export var bow_grip: XRToolsPickable
@export var string_top: Node3D
@export var string_bottom: Node3D
@export var grip_position: Node3D
@export var string_thickness := 0.01

@export_category("Audio")
@export var pull_min_db := -40.0
@export var pull_max_db := 0.0
@export var pull_pitch_max := 1.1

@onready var shot_sound: AudioStreamPlayer3D = $ShotSound
@onready var pull_sound: AudioStreamPlayer3D = $PullSound
@onready var trajectory_mesh: MeshInstance3D = $TrajectoryMesh

var arrow_body: Arrow

var _grip_held := false

var _draw_distance := 0.0
var _string_seg1: MeshInstance3D
var _string_seg2: MeshInstance3D

func _ready() -> void:
	super()
	_setup_string_visual()
	
	if bow_grip:
		bow_grip.picked_up.connect(_on_grip_picked_up)
		bow_grip.dropped.connect(_on_grip_dropped)
		
	arrow_snap.has_picked_up.connect(_on_arrow_placed)
	
	if bow_grip:
		picked_up.connect(func(_p):
			bow_grip.enabled = true
			bow_grip.show()
		)
		dropped.connect(func(_p):
			bow_grip.enabled = false
			bow_grip.hide()
		)
		bow_grip.enabled = false
		bow_grip.hide()

	_grip_held = false

func _on_arrow_placed(arrow: XRToolsPickable) -> void:
	arrow.enabled = false
	arrow_body = arrow

func _setup_string_visual() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.6, 0.4)

	_string_seg1 = MeshInstance3D.new()
	var cyl1 := CylinderMesh.new()
	cyl1.top_radius = string_thickness
	cyl1.bottom_radius = string_thickness
	cyl1.height = 0.01
	cyl1.radial_segments = 8
	_string_seg1.mesh = cyl1
	_string_seg1.material_override = mat
	_string_seg1.visible = false
	add_child(_string_seg1)

	_string_seg2 = MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl1.top_radius = string_thickness
	cyl1.bottom_radius = string_thickness
	cyl2.height = 0.01
	cyl2.radial_segments = 8
	_string_seg2.mesh = cyl2
	_string_seg2.material_override = mat
	_string_seg2.visible = false
	add_child(_string_seg2)

func _on_grip_picked_up(_pickable: XRToolsPickable) -> void:
	_grip_held = true
	pull_sound.playing = true

func _on_grip_dropped(_pickable: XRToolsPickable) -> void:
	var draw := _draw_distance
	_grip_held = false
	_draw_distance = 0.0
	_update_arrow_draw(0.0)
	_update_string_visual()
	if draw >= min_draw:
		_fire(draw)
	
	pull_sound.playing = false

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_instance_valid(bow_grip):
		return
	if not _grip_held:
		bow_grip.global_transform = grip_position.global_transform
		arrow_pivot.rotation = Vector3.ZERO
		_update_string_visual()
		_update_arrow_draw(0.15)
		_update_trajectory()
		return
	
	var draw := bow_grip.global_position.distance_to(arrow_pivot.global_position)
	_draw_distance = clamp(draw, 0.0, max_draw)
	_update_arrow_draw(_draw_distance)
	_update_string_visual()

	# Map draw distance -> perceptual (quadratic) dB and slight pitch increase
	if is_instance_valid(pull_sound) and pull_sound.playing:
		var draw_norm := 0.0
		if max_draw > 0.0001:
			draw_norm = clamp(_draw_distance / max_draw, 0.0, 1.0)
		var t := pow(draw_norm, 2.0)
		pull_sound.volume_db = lerp(pull_min_db, pull_max_db, t)
		pull_sound.pitch_scale = lerp(1.0, pull_pitch_max, t)
	else:
		# keep a quiet baseline when not actively pulling
		pull_sound.volume_db = pull_min_db
		pull_sound.pitch_scale = 1.0

	# Rotate the arrow pivot to face the grip while the grip is held
	if is_instance_valid(arrow_pivot) and is_instance_valid(bow_grip):
		var flip_target := arrow_pivot.global_position * 2.0 - bow_grip.global_position
		arrow_pivot.look_at(flip_target, Vector3.UP)

	_update_trajectory()

func _fire(draw: float) -> void:
	if arrow_body == null: return
	var dir = bow_grip.global_position.direction_to(arrow_pivot.global_position)

	shot_sound.play()
	arrow_snap.drop_object()
	var speed := lerpf(5.0, arrow_speed, draw / max_draw)
	arrow_body.fire(dir * speed)
	arrow_body = null

func _update_arrow_draw(draw: float) -> void:
	if is_instance_valid(arrow_mesh):
		arrow_mesh.position.z = arrow_mesh_rest_offset + draw

func _update_string_visual() -> void:
	if not is_instance_valid(string_top) or not is_instance_valid(string_bottom):
		if _string_seg1:
			_string_seg1.visible = false
		if _string_seg2:
			_string_seg2.visible = false
		return

	var top_local := to_local(string_top.global_position)
	var nock_local := to_local(bow_grip.global_position)
	var bottom_local := to_local(string_bottom.global_position)

	_update_segment(_string_seg1, top_local, nock_local)
	_update_segment(_string_seg2, nock_local, bottom_local)

func _update_trajectory() -> void:
	trajectory_mesh.mesh.clear_surfaces()
	
	if not _grip_held or _draw_distance < min_draw \
			or not is_instance_valid(arrow_pivot) or not is_instance_valid(bow_grip) \
			or arrow_body == null or not is_instance_valid(arrow_body):
		trajectory_mesh.hide()
		return
	
	var obj = arrow_snap.picked_up_object
	if obj and obj is Arrow:
		var elem = obj.get_element()
		var c = ArrowElement.get_element_color(elem)
		c.a = 0.8
		trajectory_mesh.material_override.albedo_color = c
	
	trajectory_mesh.show()

	var speed := lerpf(5.0, arrow_speed, _draw_distance / max_draw)
	var dir := bow_grip.global_position.direction_to(arrow_pivot.global_position)
	var velocity := dir * speed

	var gravity_strength: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var gravity_dir := ProjectSettings.get_setting("physics/3d/default_gravity_vector") as Vector3
	var gravity := gravity_dir * gravity_strength

	var pos := arrow_pivot.global_position
	const DT := 0.05

	trajectory_mesh.mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(40):
		trajectory_mesh.mesh.surface_add_vertex(to_local(pos))
		velocity += gravity * DT
		pos += velocity * DT
	trajectory_mesh.mesh.surface_end()

func _update_segment(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var length := dir.length()
	if length < 0.001:
		mi.visible = false
		return
	mi.visible = true
	var center := (a + b) * 0.5
	var y := dir.normalized()
	var up := Vector3.UP
	if abs(y.dot(up)) > 0.999:
		up = Vector3.FORWARD
	var x := up.cross(y).normalized()
	var z := y.cross(x).normalized()
	var bas := Basis(x, y, z)
	var t := Transform3D(bas, center)
	mi.transform = t
	var cyl := mi.mesh as CylinderMesh
	if cyl:
		cyl.height = length
		cyl.top_radius = string_thickness
		cyl.bottom_radius = string_thickness
