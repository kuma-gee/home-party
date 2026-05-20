extends Node3D

signal bounced(from_pos, to_pos)

@export var damage := 1
@export var max_bounces := 3
@export var bounce_delay := 0.2
@export var lightning_scene: PackedScene

@onready var hit_area: Area3D = $HitArea

var _hit_hurtboxes: Array[HurtBox] = []

func _ready() -> void:
	bounced.connect(_spawn_bolt)
	await get_tree().create_timer(0.1).timeout
	bounce_to()

func bounce_to(pos: Vector3 = global_position, bounce_count: int = 0) -> void:
	var closest: HurtBox = null
	var closest_dist := INF

	for area in hit_area.get_overlapping_areas():
		if area is HurtBox and area not in _hit_hurtboxes:
			var dist := pos.distance_to(area.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = area

	if closest == null:
		if bounce_count == 0:
			bounced.emit(null, hit_area.global_position)
		_cleanup()
		return

	_hit_hurtboxes.append(closest)
	
	var p = closest.global_position
	closest.hit(damage)
	bounced.emit(pos, p)

	if bounce_count < max_bounces:
		hit_area.global_position = p
		await get_tree().create_timer(bounce_delay).timeout
		if is_inside_tree():
			bounce_to(p, bounce_count + 1)
	else:
		_cleanup()

func _spawn_bolt(from_pos, to_pos: Vector3) -> void:
	var node = lightning_scene.instantiate()
	node.position = to_pos
	Staging.add_scene_child(node)
	
	#if from_pos is Vector3 and from_pos != to_pos:
		#var from := from_pos as Vector3
		#var length := from.distance_to(to_pos)
		#var mesh := QuadMesh.new()
		#mesh.size = Vector2(length, 0.08)
#
		#var mid := (from + to_pos) * 0.5
		#mesh.global_position = mid

	#var dir := (to_pos - from_pos).normalized()
	#if dir.length() > 0.001:
		#var ref := Vector3.FORWARD if abs(dir.dot(Vector3.UP)) > 0.99 else Vector3.UP
		#mi.global_transform.basis = Basis.looking_at(dir, ref).rotated(Vector3.RIGHT, PI * 0.5)
#
	#var tween := create_tween()
	#tween.tween_interval(0.4)
	#tween.tween_callback(mi.queue_free)

func _cleanup() -> void:
	await get_tree().create_timer(1.0).timeout
	queue_free()
