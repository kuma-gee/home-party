class_name BaseGame
extends Node

signal game_finished()

func start_game(players: Array[GameClient], game_setup: GameSetup):
	pass

func get_points() -> Dictionary[String, int]:
	return {}
