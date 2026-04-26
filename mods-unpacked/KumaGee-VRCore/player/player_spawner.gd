class_name PlayerSpawner
extends Node3D

@export var player_scene: PackedScene
@export var offset = 0.5
@export var respawn_time := 6.0

func init_players():
	var clients = PlayerManager.playing_clients
	var count = clients.size()
	if count == 0:
		return
	# Place players in a horizontal row centered on the spawner's origin.
	var center = (count - 1) / 2.0
	for i in count:
		var client = clients[i]
		var pos = Vector3.RIGHT * ((i - center) * offset)
		spawn_player(client, i, pos)

func spawn_player(game_client: GameClient, idx: int, pos: Vector3):
	var player = player_scene.instantiate() as FPSPlayer
	player.game_client = game_client
	player.player_num = idx
	player.position = pos
	player.died.connect(func():
		await get_tree().create_timer(respawn_time).timeout
		spawn_player(game_client, idx, pos)
	)
	add_child(player)
