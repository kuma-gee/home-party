class_name BaseGame
extends Node

signal game_finished()

func setup(_players: Array[GameClient], game_setup: GameSetup):
	pass

func start_game():
	pass

func get_points() -> Dictionary[String, int]:
	return {}
