class_name PlayerSpawner
extends Node3D

@export var player_scene: PackedScene
@export var offset = 0.5

func get_spawn_position(player_num: int):
	var count = PlayerManager.playing_clients.size()
	var center = (count - 1) / 2.0
	return Vector3.RIGHT * ((player_num - center) * offset)

func create_player(game_client: GameClient):
	var player = player_scene.instantiate() as FPSPlayer
	player.game_client = game_client
	player.player_num = LobbyServer.get_player_idx(game_client.uuid)
	add_child(player)
	player.position = get_spawn_position(player.player_num)
	return player
