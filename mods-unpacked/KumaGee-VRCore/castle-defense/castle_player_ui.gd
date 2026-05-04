extends JoinedPlayer

@onready var respawn_timer: Timer = $RespawnTimer

var alive := false
var player_spawner: PlayerSpawner

func _ready():
	super()
	player_spawner = get_tree().get_first_node_in_group("player_spawner")
	game_client.input_received.connect(func(input, value):
		if input == "action" and value:
			spawn_player()
	)

func can_respawn() -> bool:
	return not alive and respawn_timer.is_stopped()

func spawn_player():
	if not can_respawn():
		return

	var player = player_spawner.create_player(game_client)
	player.global_rotation.y = PI
	player.died.connect(func():
		alive = false
		respawn_timer.start()
		player.queue_free()
	)
	alive = true
