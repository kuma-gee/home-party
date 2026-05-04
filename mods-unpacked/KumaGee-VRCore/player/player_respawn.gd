class_name PlayerRespawn
extends Node3D

@export var respawn_time := 3.0
@export var game_client: GameClient
@export var pos := Vector3.ZERO
@export var player_scene: PackedScene

var alive := false
var respawn_timer := 0.0

func _ready():
	game_client.input_received.connect(func(input, value):
		if input == "action" and value:
			spawn_player()
	)

func _process(delta):
	if alive:
		return
	
	if respawn_timer > 0.0:
		respawn_timer -= delta

func can_respawn() -> bool:
	return not alive and respawn_timer <= 0.0

func spawn_player():
	if not can_respawn():
		return

	var player = player_scene.instantiate() as FPSPlayer
	player.game_client = game_client
	player.player_num = LobbyServer.get_player_idx(game_client.uuid)
	player.position = pos
	player.rotation.y = PI
	player.died.connect(func():
		alive = false
		respawn_timer = respawn_time
		player.queue_free()
	)
	add_child(player)
	alive = true
