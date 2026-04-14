class_name BaseGame
extends Node

signal game_restart()
signal game_finished()
signal back_to_menu()

func start_game(players: Array[GameClient], game_setup: GameSetup):
	pass
