class_name GameMode
extends Node

signal finished()
signal started()

@export var rounds := 2

var game_node: BaseGame
var current_round := 0
var difficulty := 0.0
var wins = {}

func start_game(game: GameResource):
	if game_node != null:
		game_node.queue_free()

	current_round = 0
	difficulty = 0.0
	game_node = game.scene.instantiate() as BaseGame
	add_child(game_node)
	
	var players = PlayerManager.get_players()
	game_node.setup(players)
	game_node.round_finished.connect(func(): _on_round_finished())
	
	wins = {}
	for p in players:
		wins[p.uuid] = 0
	
	started.emit()
	next_round()

func _on_round_finished():
	var winners = game_node.get_winners()
	for winner in winners:
		wins[winner] += 1
	
	next_round()

func next_round():
	current_round += 1
	if current_round > rounds:
		end_game()
		return

	difficulty = float(current_round) / float(rounds)
	game_node.start_game(difficulty)

func end_game():
	game_node.queue_free()
	game_node = null
	
	var players = PlayerManager.get_players()
	for p in players:
		p.reset()
	
	finished.emit()
