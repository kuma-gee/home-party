class_name NpcSpawner
extends Node

## Spawns the museum NPC crowd and assigns patrol circuits. On a wrong tag the
## Seeker calls `scatter` to make nearby NPCs break patrol briefly.

signal npcs_spawned()

@export var npc_scene: PackedScene
@export var spawn_points: Node3D
@export var route_ab: Node3D
@export var route_single_a: Node3D
@export var route_single_b: Node3D

var _npcs: Array[NpcCharacter] = []
var _spawned: bool = false


func _ready() -> void:
	spawn()


func spawn() -> void:
	if _spawned:
		return
	_spawned = true

	var markers := _collect_markers(spawn_points)
	if markers.is_empty() or not npc_scene:
		push_warning("NpcSpawner: no spawn markers or npc_scene set")
		return

	var route_ab_pts := _collect_markers(route_ab)
	var route_a_pts := _collect_markers(route_single_a)
	var route_b_pts := _collect_markers(route_single_b)

	for i in markers.size():
		var npc := npc_scene.instantiate() as NpcCharacter
		if not npc:
			continue
		add_child(npc)
		npc.global_position = markers[i].global_position
		npc.assign_route(_pick_route(route_ab_pts, route_a_pts, route_b_pts))
		npc.set_interaction_interval(12.0, 25.0)
		_npcs.append(npc)

	npcs_spawned.emit()


func scatter(origin: Vector3, radius: float, duration: float) -> void:
	for npc in _npcs:
		if not is_instance_valid(npc):
			continue
		if npc.global_position.distance_to(origin) <= radius:
			npc.scatter_from(origin, duration)


func get_npcs() -> Array[NpcCharacter]:
	return _npcs


func _collect_markers(parent: Node3D) -> Array[Marker3D]:
	var out: Array[Marker3D] = []
	if not parent:
		return out
	for child in parent.get_children():
		if child is Marker3D:
			out.append(child as Marker3D)
	return out


func _pick_route(route_ab_pts: Array[Marker3D], route_a_pts: Array[Marker3D], route_b_pts: Array[Marker3D]) -> Array[Marker3D]:
	# Two circuits: the A<->B loop, and a single-gallery loop (A or B variant).
	if route_ab_pts.is_empty() and route_a_pts.is_empty() and route_b_pts.is_empty():
		return []
	var use_ab := randf() < 0.5 or (route_a_pts.is_empty() and route_b_pts.is_empty())
	if use_ab and not route_ab_pts.is_empty():
		return route_ab_pts
	# Single-gallery loop: pick A or B whichever is available.
	if not route_a_pts.is_empty() and not route_b_pts.is_empty():
		return route_a_pts if randf() < 0.5 else route_b_pts
	if not route_a_pts.is_empty():
		return route_a_pts
	return route_b_pts
