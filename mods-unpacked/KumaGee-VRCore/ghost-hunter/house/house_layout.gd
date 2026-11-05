class_name HouseLayout
extends Node3D

## One haunted-house layout variant. Markers are queryable through the
## getters below (and via the gh_* groups) for the other Ghost Hunter slices:
## GH-3 hunter spawn outside the front door, GH-4 ghost spawns, GH-8
## hauntable-object spots, GH-9 task markers, GH-11 haunt-surge exit.

const GROUP_FRONT_DOOR := "gh_front_door"
const GROUP_GHOST_SPAWN := "gh_ghost_spawn"
const GROUP_HAUNT_SPOT := "gh_haunt_spot"
const GROUP_TASK_SPOT := "gh_task_spot"


func get_front_door() -> Marker3D:
	return _first_marker_in_group(GROUP_FRONT_DOOR)


func get_camera() -> Camera3D:
	for node in find_children("*", "Camera3D", true, false):
		return node
	return null


func get_ghost_spawn_points() -> Array[Marker3D]:
	return _markers_in_group(GROUP_GHOST_SPAWN)


func get_hauntable_spots() -> Array[Marker3D]:
	return _markers_in_group(GROUP_HAUNT_SPOT)


func get_task_spots() -> Array[Marker3D]:
	return _markers_in_group(GROUP_TASK_SPOT)


func _first_marker_in_group(group: String) -> Marker3D:
	for marker in _markers_in_group(group):
		return marker
	return null


func _markers_in_group(group: String) -> Array[Marker3D]:
	var out: Array[Marker3D] = []
	for node in find_children("*", "Marker3D", true, false):
		if node.is_in_group(group):
			out.append(node)
	return out
