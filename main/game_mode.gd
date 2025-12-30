class_name GameMode
extends Node

signal finished()
signal started()

@export var num_of_games := 5

var played_games := 0
var games: Array[GameResource]
var game_node: BaseGame
var wins = {}
var playing := false

func start_games(selected_games: Array[GameResource]):
	wins = {}
	games = selected_games
	started.emit()
	playing = true
	next_game()

func next_game():
	if played_games >= num_of_games:
		end_game()
		return
	
	if game_node != null:
		game_node.queue_free()

	var res = games.pick_random()
	game_node = res.scene.instantiate() as BaseGame
	add_child(game_node)
	
	var players = PlayerManager.get_players()
	var game_setup = GameSetup.new()
	game_node.game_finished.connect(func(): _on_game_finished())
	game_node.start_game(players, game_setup)
	played_games += 1

func _on_game_finished():
	var points = game_node.get_points()
	for uuid in points:
		wins[uuid] += points[uuid]
	
	next_game()

func end_game():
	if game_node:
		game_node.queue_free()
		game_node = null
	
	var players = PlayerManager.get_players()
	for p in players:
		p.reset()
	
	playing = false
	finished.emit()
