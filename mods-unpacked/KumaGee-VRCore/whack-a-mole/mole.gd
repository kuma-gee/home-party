class_name Mole
extends Node3D

signal hit()
signal miss()

@export var player_colors: Array[Color] = [
	Color.RED,
	Color.DEEP_SKY_BLUE,
	Color.ORANGE,
	Color.GREEN,
	Color.YELLOW,
	Color.HOT_PINK,
	Color.MEDIUM_PURPLE,
]
@export var color_rect: ColorRect
@export_range(0.02, 0.5, 0.01) var focus_ring_width := 0.16
@export_range(0.0, 0.2, 0.01) var focus_ring_gap := 0.02
@export_range(0.0, 0.8, 0.01) var center_hole_radius := 0.18

@onready var area_3d: Area3D = $Area3D
@onready var mole: Node3D = $mole

var tw: Tween
var player_indexes: Array[int] = []
var _focus_rings: Array[ColorRect] = []
var active := false

func _ready() -> void:
	_setup_focus_rings()
	_update_focus_highlight()
	mole.position.y = -0.2
	area_3d.body_entered.connect(func(_b): _on_hit())

func _on_hit():
	if not active: return
	if tw and tw.is_running():
		tw.stop()
	
	print("Hit!")
	hit.emit()
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mole, "position:y", -0.1, 0.5)
	get_tree().create_timer(1.0).timeout.connect(func(): hide_mole())

func hide_mole():
	if tw and tw.is_running():
		tw.stop()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mole, "position:y", -0.2, 0.5)
	tw.finished.connect(func(): active = false)

func activate():
	if active: return
	if tw and tw.is_running():
		return
	
	active = true
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mole, "position:y", 0.0, 0.5)
	tw.tween_property(mole, "position:y", -0.2, 0.5).set_ease(Tween.EASE_IN).set_delay(0.5)
	tw.finished.connect(func():
		miss.emit()
		active = false
	)

func set_focused_players(indexes: Array[int]) -> void:
	player_indexes = indexes.duplicate()
	_update_focus_highlight()

func add_focused_player(player_idx: int) -> void:
	if player_indexes.has(player_idx):
		return
	player_indexes.append(player_idx)
	_update_focus_highlight()

func remove_focused_player(player_idx: int) -> void:
	if not player_indexes.has(player_idx):
		return
	player_indexes.erase(player_idx)
	_update_focus_highlight()

func clear_focused_players() -> void:
	if player_indexes.is_empty():
		return
	player_indexes.clear()
	_update_focus_highlight()

func _setup_focus_rings() -> void:
	if color_rect == null:
		return

	if color_rect.material is ShaderMaterial:
		color_rect.material = (color_rect.material as ShaderMaterial).duplicate()

	_focus_rings.clear()
	_focus_rings.append(color_rect)

func _ensure_focus_ring_count(count: int) -> void:
	if color_rect == null:
		return

	while _focus_rings.size() < count:
		var ring := ColorRect.new()
		ring.name = "FocusRing_%d" % _focus_rings.size()
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.grow_horizontal = Control.GROW_DIRECTION_BOTH
		ring.grow_vertical = Control.GROW_DIRECTION_BOTH
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.color = Color.WHITE

		if color_rect.material is ShaderMaterial:
			ring.material = (color_rect.material as ShaderMaterial).duplicate()

		color_rect.get_parent().add_child(ring)
		_focus_rings.append(ring)

func _max_ring_count() -> int:
	var step := focus_ring_width + focus_ring_gap
	if step <= 0.0:
		return 0
	var usable := maxf(0.0, 1.0 - center_hole_radius)
	return maxi(1, int(floor(usable / step)) + 1)

func _update_focus_highlight() -> void:
	if color_rect == null:
		return

	var unique_players: Array[int] = []
	for idx in player_indexes:
		if not unique_players.has(idx):
			unique_players.append(idx)

	var max_rings := _max_ring_count()
	if max_rings <= 0:
		for ring in _focus_rings:
			ring.visible = false
		return

	if unique_players.size() > max_rings:
		unique_players.resize(max_rings)

	_ensure_focus_ring_count(unique_players.size())

	for i in _focus_rings.size():
		var ring: ColorRect = _focus_rings[i]
		if i >= unique_players.size():
			ring.visible = false
			continue

		var outer := clampf(1.0 - float(i) * (focus_ring_width + focus_ring_gap), 0.0, 1.0)
		var inner := clampf(outer - focus_ring_width, center_hole_radius, outer)
		var material := ring.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("radius", outer)
			material.set_shader_parameter("inner_radius", inner)
			material.set_shader_parameter("fill", 1.0)
			ring.color = player_colors[unique_players[i] % player_colors.size()]
			material.set_shader_parameter("inner_color", Color(0.0, 0.0, 0.0, 0.0))

		ring.visible = true
