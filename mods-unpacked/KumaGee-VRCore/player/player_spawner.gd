class_name PlayerSpawner
extends Node3D

@export var player_scene: PackedScene
@export var offset = 0.5

func init_players():
	var clients = PlayerManager.playing_clients
	var angle = TAU / clients.size()
	for i in clients.size():
		var client = clients[i]
		var player = spawn_player(client)
		player.player_num = i
		player.position = Vector3.FORWARD.rotated(Vector3.UP, angle * i) * offset

func spawn_player(game_client: GameClient) -> FPSPlayer:
	var player = player_scene.instantiate() as FPSPlayer
	player.game_client = game_client
	add_child(player)
	return player
