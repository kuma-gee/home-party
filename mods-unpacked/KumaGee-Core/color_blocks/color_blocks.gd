extends BaseGame

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

@export var max_grid_size := 24
@export var min_grid_size := 10

@onready var game_time: Timer = $GameTime
@onready var start_time: Timer = $StartTime
@onready var team_split: Node = $TeamSplit
@onready var create_grid: Node = $CreateGrid

var blocks := []
var player_nodes: Array[Node3D] = []
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
	teams = team_split.create_teams(players, colors.size(), game_setup.team_mode)
	var i = clamp(teams.size() / float(colors.size()), 0.0, 1.0)
	var grid_size = int(ceil(lerp(min_grid_size, max_grid_size, i)))
	blocks = create_grid.create_grid(grid_size)
	_create_players()

func start_game(_diff := 0.0):
	winners = []
	winner_label.hide()
	start_time.start()

func get_winners() -> Array[String]:
	return winners

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
			var grid_pos = create_grid.get_random_position(used_positions)
			used_positions.append(grid_pos)
			node.position = grid_pos

			player_nodes.append(node)
