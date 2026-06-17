extends Node

@export var pet_scene: PackedScene
@export var spawn_points: Node3D
@export var player_list: PlayerList

var _pets: Dictionary[String, DrawGuessPet] = {}
var _spawn_index := 0


func _ready() -> void:
	player_list.player_created.connect(_on_player_created)
	player_list.player_removed.connect(_on_player_removed)


func _get_spawn_points() -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	for child in spawn_points.get_children():
		if child is Marker3D:
			points.append(child)
	return points


func _on_player_created(uuid: String) -> void:
	var spawn_points_arr = _get_spawn_points()
	if spawn_points_arr.is_empty():
		return

	var point = spawn_points_arr[_spawn_index % spawn_points_arr.size()]
	_spawn_index += 1

	var pet = pet_scene.instantiate() as DrawGuessPet
	pet.global_position = point.global_position
	pet.rotation = Vector3(0, randf_range(0, TAU), 0)
	add_child(pet)

	var idx = PlayerManager.get_player_idx(uuid)
	var color = PlayerList.get_color(idx)
	var controller = PlayerManager.find_player_by_uuid(uuid)
	pet.setup(idx, uuid, color, controller)

	_pets[uuid] = pet


func _on_player_removed(uuid: String) -> void:
	if _pets.has(uuid):
		_pets[uuid].queue_free()
		_pets.erase(uuid)


func get_pet(uuid: String) -> DrawGuessPet:
	return _pets.get(uuid) as DrawGuessPet
