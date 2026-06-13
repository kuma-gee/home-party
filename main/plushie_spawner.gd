extends Node

@export var plushie_scene: PackedScene
@export var spawn_point_group: Node3D
@export var player_list: PlayerList

var _plushies := {}  # uuid -> plushie node
var _spawn_index := 0

func _ready() -> void:
	player_list.player_created.connect(_on_player_created)
	player_list.player_removed.connect(_on_player_removed)

func _get_spawn_points() -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	for child in spawn_point_group.get_children():
		if child is Marker3D and child.name.begins_with("PlushieSpawn"):
			points.append(child)
	return points

func _on_player_created(uuid: String) -> void:
	var spawn_points = _get_spawn_points()
	if spawn_points.is_empty():
		return

	var point = spawn_points[_spawn_index % spawn_points.size()]
	_spawn_index += 1

	var plushie = plushie_scene.instantiate()
	plushie.position = point.global_position
	plushie.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
	Staging.add_scene_child(plushie)

	var idx = PlayerManager.get_player_idx(uuid)
	var color = PlayerList.get_color(idx)
	var controller = PlayerManager.find_player_by_uuid(uuid)
	plushie.setup(idx, uuid, color, controller)

	_plushies[uuid] = plushie

func _on_player_removed(uuid: String) -> void:
	if _plushies.has(uuid):
		_plushies[uuid].queue_free()
		_plushies.erase(uuid)
