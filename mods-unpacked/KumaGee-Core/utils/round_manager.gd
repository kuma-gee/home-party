class_name RoundManager
extends Node

signal start_round()
signal end_rounds()

@export var rounds := 5

var current_round := 0
var difficulty := 0.0
var wins: Dictionary[String, int] = {}

func start_rounds(players: Array[GameClient]):
	current_round = 0
	difficulty = 0.0
	
	wins = {}
	for p in players:
		wins[p.uuid] = 0
	
	next_round()

func finish_round(winners: Array[String]):
	for winner in winners:
		wins[winner] += 1
	
	next_round()

func next_round():
	current_round += 1
	if current_round > rounds:
		end_game()
		return

	difficulty = float(current_round) / float(rounds)
	start_round.emit(difficulty)

func end_game():
	var players = PlayerManager.get_players()
	for p in players:
		p.reset()
	
	end_rounds.emit()
