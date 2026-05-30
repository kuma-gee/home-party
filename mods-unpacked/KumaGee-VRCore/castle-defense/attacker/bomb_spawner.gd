class_name BombSpawner
extends Node3D

@export var bomb_scene: PackedScene
@export var bomb_count: int = 5
@export var offset: Vector3 = Vector3(0.5, 0, 0)

func _ready() -> void:
	spawn_bombs()

func spawn_bombs() -> void:
	var start_pos: Vector3 = global_position
	var mid := (bomb_count - 1) / 2.0
	for i in range(bomb_count):
		var pos: Vector3 = start_pos + offset * (i - mid)
		_spawn_bomb(pos)

var _stopped := false

func stop() -> void:
	_stopped = true

func _spawn_bomb(pos: Vector3) -> void:
	if _stopped:
		return
	var bomb = bomb_scene.instantiate() as XRToolsPickable
	bomb.position = pos
	bomb.picked_up.connect(func(_p):
		await get_tree().create_timer(3.0).timeout
		_spawn_bomb(pos)
	)
	Staging.add_scene_child(bomb)
