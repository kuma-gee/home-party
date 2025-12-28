extends BaseGame

@export var camera: Camera3D
@export var block_scene: PackedScene
@export var player_scene: PackedScene
@export var player_block_scene: PackedScene
@export var winner_label: Label

@export var colors: Array[Color] = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
	Color.YELLOW,
	Color.ORANGE,
	Color.PURPLE,
	Color.CYAN,
	Color.MAGENTA,
]

@export var color_names = [
	"Red",
	"Green",
	"Blue",
	"Yellow",
	"Orange",
	"Purple",
	"Cyan",
	"Magenta",
]

@export_category("Grid")
@export var max_grid_size := 24
@export var min_grid_size := 10
@export var grid_spacing := 1.0

@export_category("Blocks")
@export var floor_box: CSGBox3D
@export var east_wall_box: CSGBox3D
@export var west_wall_box: CSGBox3D
@export var north_wall_box: CSGBox3D
@export var south_wall_box: CSGBox3D

@onready var game_time: Timer = $GameTime
@onready var start_time: Timer = $StartTime

var blocks := []
var player_nodes: Array[Node3D] = []
var grid_size = min_grid_size
var spacing = grid_spacing
var teams = {}
var winners = []

func _ready() -> void:
	start_time.timeout.connect(func(): _start())
	game_time.timeout.connect(func(): _end_game())

func _start():
	game_time.start()
	for p in player_nodes:
		p.locked = false

func _end_game():
	for p in player_nodes:
		p.locked = true
	
	var color_count = {}
	for b in blocks:
		var idx = colors.find(b.current_color)
		if not idx in color_count:
			color_count[idx] = 0
		color_count[idx] += 1
	
	var highest_count = 0
	var winning_color_idx = -1
	for idx in color_count:
		if color_count[idx] > highest_count and idx >= 0:
			highest_count = color_count[idx]
			winning_color_idx = idx
	
	if winning_color_idx >= 0:
		winner_label.text = "%s won!" % color_names[winning_color_idx]
		winner_label.show()

		for team_id in teams:
			var team_color_idx = team_id % colors.size()
			if team_color_idx == winning_color_idx:
				for player in teams[team_id]:
					winners.append(player.uuid)
	
	await get_tree().create_timer(2.0).timeout
	game_finished.emit()
		
func setup(players: Array[GameClient], game_setup: GameSetup):
	teams = _create_teams(players, game_setup.team_mode)
	_create_grid()
	_create_players()
	_position_camera()
	_setup_floor_and_walls()

func start_game(_diff := 0.0):
	winners = []
	winner_label.hide()
	start_time.start()

func get_winners() -> Array[String]:
	return winners

func _setup_floor_and_walls():
	floor_box.size.x = grid_size * spacing
	floor_box.size.z = grid_size * spacing

	var offset = -spacing / 2.0
	floor_box.position.x = offset
	floor_box.position.z = offset

	east_wall_box.size.z = grid_size * spacing
	west_wall_box.size.z = grid_size * spacing
	north_wall_box.size.z = grid_size * spacing
	south_wall_box.size.z = grid_size * spacing
	east_wall_box.position.x = (grid_size * spacing) / 2.0 + (east_wall_box.size.y / 2.0) + offset
	east_wall_box.position.z = offset
	west_wall_box.position.x = -((grid_size * spacing) / 2.0 + (west_wall_box.size.y / 2.0) - offset)
	west_wall_box.position.z = offset
	north_wall_box.position.z = -((grid_size * spacing) / 2.0 + (north_wall_box.size.y / 2.0) - offset)
	north_wall_box.position.x = offset
	south_wall_box.position.z = (grid_size * spacing) / 2.0 + (south_wall_box.size.y / 2.0) + offset
	south_wall_box.position.x = offset
	east_wall_box.hide()
	west_wall_box.hide()
	north_wall_box.hide()
	south_wall_box.hide()

func _create_grid():
	var i = clamp(teams.size() / float(colors.size()), 0.0, 1.0)
	grid_size = int(ceil(lerp(min_grid_size, max_grid_size, i)))
	spacing = grid_spacing

	for x in range(grid_size):
		for z in range(grid_size):
			var block = block_scene.instantiate() as Node3D
			block.position = Vector3(
				(x - grid_size / 2.0) * spacing,
				0.0,
				(z - grid_size / 2.0) * spacing
			)
			add_child(block)
			blocks.append(block)

func _position_camera():
	if not camera:
		return
	
	var grid_world_size = grid_size * spacing
	var fov_rad = deg_to_rad(camera.fov)
	var distance = (grid_world_size / 2.0) / tan(fov_rad / 2.0)
	
	distance *= 1.5
	
	var angle = deg_to_rad(60)
	camera.position = Vector3(0, distance * sin(angle), distance * cos(angle))
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _create_teams(players: Array[GameClient], split := false) -> Dictionary:
	var split_teams = split or players.size() > colors.size()
	var teams = {}

	if split_teams and players.size() > 3:
		# Calculate optimal team size based on number of players
		# Aim for 2-4 players per team, while not exceeding available colors
		var num_players = players.size()
		var max_teams = colors.size()
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

func _get_random_grid_position(used_positions: Array) -> Vector2i:
	var max_attempts = 100
	var attempts = 0
	
	while attempts < max_attempts:
		var x = randi() % grid_size
		var z = randi() % grid_size
		var pos = Vector2i(x, z)
		
		if pos not in used_positions:
			return pos
		
		attempts += 1
	
	# Fallback: return any position if all attempts failed
	return Vector2i(randi() % grid_size, randi() % grid_size)

func _create_players():
	var used_positions = []
	
	for team in teams:
		var color = colors[team % colors.size()]
		for player in teams[team]:
			var node = player_scene.instantiate() as Node3D
			node.game_client = player
			add_child(node)

			var player_block = player_block_scene.instantiate() as Node3D
			player_block.color = color
			node.add_child(player_block)
			
			# Position player at random grid position
			var grid_pos = _get_random_grid_position(used_positions)
			used_positions.append(grid_pos)
			node.position = Vector3(
				(grid_pos.x - grid_size / 2.0) * spacing,
				0.5,  # Slightly above the grid
				(grid_pos.y - grid_size / 2.0) * spacing
			)

			player_nodes.append(node)
