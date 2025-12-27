class_name PlayerGameList
extends AnimeContainer

@export var player_row: PackedScene

func add_players(players: Array[CountPlayer]) -> void:
	for p in players:
		var row = player_row.instantiate() as PlayerRow
		row.count_player = p
		add_child(row)
	
	focused_index = int(players.size() / 2.0)
	init()
