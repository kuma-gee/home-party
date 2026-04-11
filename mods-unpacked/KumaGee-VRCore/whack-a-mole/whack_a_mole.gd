extends BaseGame

@export var score: Label
@export var whack_spawn: Node3D
@export var reset_whack_button: XRToolsInteractableAreaButton

@onready var player_root: Node = $PlayerRoot
@onready var moles: Node3D = $Moles
@onready var play_time: Timer = $PlayTime
@onready var whack: XRToolsPickable = $Whack

var hits := 0:
	set(v):
		hits = v
		score.text = "%s" % hits
var misses := 0

func _ready() -> void:
	hits = 0
	play_time.timeout.connect(_on_game_finished)
	reset_whack_button.button_pressed.connect(func():
		whack.rotation_degrees = Vector3(180, 0, 0)
		whack.global_position = whack_spawn.global_position
	)

func _on_game_finished():
	print("Game finished! Hits: %d, Misses: %d" % [hits, misses])

func start_game(players: Array[GameClient], _game_setup: GameSetup):
	var mole_list := moles.get_children()
	
	for m in mole_list:
		m.hit.connect(func(): hits += 1)
		m.miss.connect(func(): misses += 1)

	for i in range(players.size()):
		var player_mole := PlayerMole.new()
		player_mole.game_client = players[i]
		player_mole.max_mole = mole_list.size()
		player_root.add_child(player_mole)

		# Set initial focus on mole 0
		if mole_list.size() > 0:
			(mole_list[0] as Mole).add_focused_player(i)

		var player_idx := i
		player_mole.moved.connect(func(new_idx: int): _on_player_moved(player_idx, new_idx))
		player_mole.activate.connect(func(idx: int): _on_player_activate(player_idx, idx))
	
	play_time.start()

func _on_player_moved(player_idx: int, new_idx: int):
	if play_time.is_stopped(): return
	
	for mole in moles.get_children():
		(mole as Mole).remove_focused_player(player_idx)
	(moles.get_children()[new_idx] as Mole).add_focused_player(player_idx)

func _on_player_activate(player_idx: int, idx: int):
	if play_time.is_stopped(): return
	
	var mole := moles.get_children()[idx] as Mole
	mole.activate()
