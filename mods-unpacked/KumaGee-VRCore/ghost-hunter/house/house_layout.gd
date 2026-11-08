class_name HouseLayout
extends Node3D

## One haunted-house layout variant. Markers are queryable through the
## getters below (and via the gh_* groups) for the other Ghost Hunter slices:
## GH-3 hunter spawn outside the front door, GH-4 ghost spawns, GH-8
## hauntable-object spots (props are spawned here in _ready), GH-9 task
## markers, GH-11 haunt-surge exit.

const GROUP_FRONT_DOOR := "gh_front_door"
const GROUP_GHOST_SPAWN := "gh_ghost_spawn"
const GROUP_HAUNT_SPOT := "gh_haunt_spot"
const GROUP_TASK_SPOT := "gh_task_spot"

const HAUNTABLE_SCENE := preload("res://mods-unpacked/KumaGee-VRCore/ghost-hunter/hauntable_object.tscn")
## Effect types assigned to consecutive haunt spots so each house mixes
## flicker lamps, creaking furniture, and twitching dolls.
const HAUNT_EFFECT_CYCLE := [
	HauntableObject.EffectType.FLICKER,
	HauntableObject.EffectType.CREAK,
	HauntableObject.EffectType.TWITCH,
	HauntableObject.EffectType.TWITCH,
	HauntableObject.EffectType.CREAK,
]


func _ready() -> void:
	_spawn_hauntable_objects()


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


func get_hauntable_objects() -> Array[HauntableObject]:
	var out: Array[HauntableObject] = []
	for node in find_children("*", "HauntableObject", true, false):
		out.append(node)
	return out


## GH-8: place a hauntable prop at every gh_haunt_spot marker (the spots
## themselves were placed in GH-2) so ghosts have objects to possess.
func _spawn_hauntable_objects() -> void:
	var spots := get_hauntable_spots()
	for i in range(spots.size()):
		var obj := HAUNTABLE_SCENE.instantiate() as HauntableObject
		obj.name = "HauntableObject%d" % i
		obj.effect_type = HAUNT_EFFECT_CYCLE[i % HAUNT_EFFECT_CYCLE.size()]
		spots[i].add_child(obj)


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
