class_name PlayerSpawner
extends Node3D

@export var player_scene: PackedScene
@export var offset = 0.5

var clients: Array
var alive := {}
var center := 0.0

func init_players():
	clients = PlayerManager.playing_clients
	var count = clients.size()
	if count == 0:
		return

	center = (count - 1) / 2.0
	for i in count:
		var spawner = PlayerRespawn.new()
		spawner.idx = i
		spawner.game_client = clients[i]
		spawner.player_scene = player_scene
		spawner.pos = Vector3.RIGHT * ((i - center) * offset)
		add_child(spawner)
