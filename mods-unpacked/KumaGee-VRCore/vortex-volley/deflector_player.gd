class_name DeflectorPlayer
extends Node3D

const MOVE_SPEED: float = 2.0
const HALF_PADDLE_WIDTH: float = 0.65
const FLASH_DURATION: float = 0.2

var controller: ClientController
var player_name: String = ""
var lives: int = 3
var base_angle: float = 0.0
var zone_half_arc: float = PI / 4.0
var arena_radius: float = 4.5

var _offset: float = 0.0
var _move_input: Vector2 = Vector2.ZERO
var _mat: StandardMaterial3D

func _ready() -> void:
	var idx := PlayerManager.get_player_idx(controller.uuid) if controller else 0
	var color := PlayerList.get_color(idx)

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(HALF_PADDLE_WIDTH * 2.0, 0.5, 0.2)
	mi.mesh = box
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = color
	_mat.emission_enabled = true
	_mat.emission = color
	_mat.emission_energy_multiplier = 0.6
	mi.material_override = _mat
	add_child(mi)

	var label := Label3D.new()
	label.text = "P%d" % (idx + 1)
	label.pixel_size = 0.03
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.55, 0)
	add_child(label)

func _physics_process(delta: float) -> void:
	var input := controller.get_move() if controller else _move_input
	var max_off := zone_half_arc * 0.6
	_offset = clamp(_offset + input.x * MOVE_SPEED * delta, -max_off, max_off)
	_update_transform()

func _update_transform() -> void:
	var angle := base_angle + _offset
	global_position = Vector3(cos(angle) * arena_radius, GameOrb.ORB_HEIGHT, sin(angle) * arena_radius)
	var target := Vector3(0.0, GameOrb.ORB_HEIGHT, 0.0)
	if global_position.distance_to(target) > 0.01:
		look_at(target, Vector3.UP)
		rotate_y(PI)

func update_position(radius: float) -> void:
	arena_radius = radius
	_update_transform()

func covers_angle(impact_angle: float) -> bool:
	if lives <= 0:
		return false
	var my_angle := base_angle + _offset
	var half_w := atan2(HALF_PADDLE_WIDTH, arena_radius)
	return abs(_angle_diff(impact_angle, my_angle)) <= half_w

func is_base_zone(angle: float) -> bool:
	return abs(_angle_diff(angle, base_angle)) <= zone_half_arc

func flash_hit() -> void:
	if not _mat:
		return
	_mat.emission_energy_multiplier = 3.0
	var tw := create_tween()
	tw.tween_property(_mat, "emission_energy_multiplier", 0.6, FLASH_DURATION)

func _on_moved(dir: Vector2) -> void:
	_move_input = dir

func _angle_diff(a: float, b: float) -> float:
	return fmod(a - b + PI * 3.0, TAU) - PI
