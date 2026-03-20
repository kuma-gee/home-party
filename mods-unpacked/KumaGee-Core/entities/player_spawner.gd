extends Node3D

@export var player_scene: PackedScene

var players: Array[Node3D] = []

func spawn_players(list: Array[GameClient], customize: Callable):
	for i in range(list.size()):
		var p = list[i]
		var player = spawn_player(p)
		customize.call(player, i)

func spawn_player(player: GameClient):
	var node = player_scene.instantiate() as Node3D
	node.game_client = player
	add_child(node)
	players.append(node)
	return node

func reset():
	for p in players:
		p.queue_free()
	players = []
