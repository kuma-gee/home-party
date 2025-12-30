extends BaseGame

@export var player_scene: PackedScene
@onready var create_grid: Node = $CreateGrid
@onready var game_start: CanvasLayer = $GameStart

var winners = []
var blocks = []

func _ready() -> void:
	game_start.game_started.connect(func(): _on_game_started())
	game_start.game_ended.connect(func(): _on_game_ended())

func _on_game_started():
	for b in blocks:
		b.set_locked(false)

func _on_game_ended():
	for b in blocks:
		b.set_locked(true)
	
	var alive_players := []
	for player in game_start.player_nodes:
		if player.is_dead: continue
		alive_players.append(player)
	
	await get_tree().create_timer(2.0).timeout
	game_finished.emit()

func start_game(players: Array[GameClient], _game_setup: GameSetup):
	blocks = create_grid.create_grid(players.size() / 8.0)
	var player_nodes = _create_players(players)
	game_start.start_game(player_nodes)

func _create_players(players: Array[GameClient]):
	var result: Array[Node3D] = []
	for player in players:
		var node = player_scene.instantiate() as Node3D
		node.game_client = player
		node.enable_jump()
		add_child(node)
		node.died.connect(func():
			if _is_all_dead():
				game_start.end_game()
		)
		node.position = create_grid.get_random_position()
		result.append(node)
	
	return result

func _is_all_dead():
	for player in game_start.player_nodes:
		if not player.is_dead:
			return false
	return true
