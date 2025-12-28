extends Node

func create_teams(players: Array[GameClient], max_teams: int, split := false) -> Dictionary:
	var split_teams = split or players.size() > max_teams
	var teams = {}

	if split_teams and players.size() > 3:
		# Calculate optimal team size based on number of players
		# Aim for 2-4 players per team, while not exceeding available colors
		var num_players = players.size()
		var team_size = 2
		
		if num_players > max_teams:
			team_size = ceil(float(num_players) / float(max_teams))
		else:
			team_size = ceil(num_players / 2.0)
		team_size = clamp(team_size, 2, 4)

		var team_id = 0
		var current_team_members = 0
		
		# Split players into teams of team_size
		for player in players:
			# Create a new team if the current one is full or doesn't exist
			if current_team_members >= team_size or team_id not in teams:
				if current_team_members >= team_size:
					team_id += 1
				teams[team_id] = []
				current_team_members = 0
			
			# Add player to current team
			teams[team_id].append(player)
			current_team_members += 1
	else:
		for i in range(players.size()):
			teams[i] = [players[i]]

	return teams
