extends BaseGame

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

@onready var team_split: Node = $TeamSplit
@onready var create_grid: Node = $CreateGrid
@onready var game_start: CanvasLayer = $GameStart
@onready var player_spawner: Node3D = $PlayerSpawner

var blocks := []
var teams = {}
var winners = []

func _ready() -> void:
	game_start.game_ended.connect(func(): _end_game())

func _end_game():
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

		for team_id in teams:
			var team_color_idx = team_id % colors.size()
			if team_color_idx == winning_color_idx:
				for player in teams[team_id]:
					winners.append(player.uuid)
	
	await get_tree().create_timer(2.0).timeout
	game_finished.emit()
	
func start_game(players: Array[GameClient], game_setup: GameSetup):
	winners = []
	teams = team_split.create_teams(players, colors.size(), game_setup.team_mode)
	blocks = create_grid.create_grid(teams.size() / float(colors.size()))
	
	player_spawner.reset()
	for team in teams:
		var color = colors[team % colors.size()]
		player_spawner.create_players(teams[team], func(p, _i): _setup_player(p, color))
		
	game_start.start_game(player_spawner.players)

func _setup_player(node: Node3D, color: Color):
	node.enable_stun()
	node.enable_color(color)
	node.position = create_grid.get_random_position()
