class_name BaseGame
extends Node

signal round_finished()

func setup(_players: Array[GameClient]):
	pass

func start_game(_diff := 0.0):
	pass

func get_winners() -> Array[String]:
	return []
