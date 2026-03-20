extends BaseGame

@export var spawn_radius := 3.0
@onready var game_start: CanvasLayer = $GameStart
@onready var player_spawner: Node3D = $PlayerSpawner

var winners = []

func _ready() -> void:
	game_start.game_ended.connect(func(): _on_game_ended())

func _on_game_ended():
	var alive_players := []
	for player in game_start.player_nodes:
		if player.is_dead: continue
		alive_players.append(player)
	
	await get_tree().create_timer(2.0).timeout
	game_finished.emit()

func start_game(players: Array[GameClient], _game_setup: GameSetup):
	var spawn_angle = TAU / players.size()
	player_spawner.reset()
	player_spawner.create_players(players, func(x, i): _setup_player(x, spawn_angle * i))
	game_start.start_game(player_spawner.players)

func _setup_player(node: Node3D, spawn_angle: float):
	node.enable_jump()
	node.position = Vector3.FORWARD.rotated(Vector3.UP, spawn_angle) * spawn_radius
	node.died.connect(func():
		if _is_all_dead():
			game_start.end_game()
	)

func _is_all_dead():
	for player in game_start.player_nodes:
		if not player.is_dead:
			return false
	return true
