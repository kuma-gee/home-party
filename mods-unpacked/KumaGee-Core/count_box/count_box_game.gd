extends BaseGame

@export var player_game_list: PlayerGameList
@export var box_root: Node3D
@export var count_label: Label

@export_category("Box")
@export var box_size := 1.0
@export var box_spacing := 1.0
@export var grid_size := 8
@export var movement_distance := 12.0
@export var start_marker: Node3D

@export_category("Difficulty")
@export var box_count_diff := 3
@export var min_box_count := 3
@export var max_box_count := 20
@export var min_show_time := 0.5
@export var max_show_time := 3.0
@export var min_box_speed := 0.5
@export var max_box_speed := 3.0

@onready var game_timer: Timer = $GameTimer
@onready var hide_timer: Timer = $HideTimer
@onready var start_timer: Timer = $StartTimer
@onready var check_lock_timer: Timer = $CheckLockTimer

var is_finished := false
var count_players: Array[CountPlayer] = []
var difficulty := 0.0
var box_count := 0

func _ready() -> void:
	box_root.hide()
	hide_timer.timeout.connect(func():
		box_root.hide()
		game_timer.start()
	)
	game_timer.timeout.connect(func(): _evaluate_count())
	start_timer.timeout.connect(func(): _spawn())
	check_lock_timer.timeout.connect(func():
		if not is_finished and _is_all_locked():
			game_timer.stop()
			game_timer.timeout.emit()
	)

func _evaluate_count():
	if is_finished: return
	
	is_finished = true
	for c in count_players:
		c.lock()
	
	count_label.text = ""
	count_label.show()
	
	box_root.show()
	box_root.position = Vector3.ZERO
	for i in range(box_count):
		count_label.text = "%s" % (i + 1)
		await get_tree().create_timer(0.3).timeout
	
	for c in count_players:
		c.is_winner = c.count == box_count
		
	await get_tree().create_timer(2.0).timeout
	round_finished.emit()

func get_winners():
	return count_players.filter(func(x): return x.is_winner).map(func(x): return x.game_client.uuid)

func setup(players: Array[GameClient]):
	for p in players:
		var player = CountPlayer.new()
		player.game_client = p
		player.locked_changed.connect(func(l):
			if l: check_lock_timer.start()
		)
		add_child(player)
		count_players.append(player)
	
	player_game_list.add_players(count_players)

func _is_all_locked():
	for p in count_players:
		if not p.is_locked:
			return false
	return true

func reset_game():
	for child in box_root.get_children():
		child.queue_free()
	for player in count_players:
		player.reset()
	
	is_finished = false
	count_label.hide()
	box_root.hide()

func start_game(diff := 0.0):
	reset_game()
	difficulty = diff
	start_timer.start()

func _spawn():
	for c in count_players:
		c.start()
	
	box_count = int(lerp(min_box_count, max_box_count, difficulty))
	box_count += randi_range(-box_count, box_count_diff)
	box_count = max(box_count, min_box_count)

	var positions := []
	for i in range(box_count):
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		while pos in positions:
			pos = Vector2(randi() % grid_size, randi() % grid_size)
		_create_box(pos)
		positions.append(pos)
	
	if difficulty > 0.5:
		var dir = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT].pick_random()
		_move_boxes(dir, lerp(max_box_speed, min_box_speed, difficulty))
	else:
		hide_timer.start(lerp(max_show_time, min_show_time, difficulty))
	
	box_root.show()
	
func _move_boxes(dir: Vector3, time: float):
	var tween = create_tween()
	var start = Vector3.ZERO - dir * movement_distance
	var end = Vector3.ZERO + dir * movement_distance

	box_root.position = start
	tween.tween_property(box_root, "position", end, time)
	tween.finished.connect(func(): box_root.hide())

func _create_box(pos: Vector2):
	var box = CSGBox3D.new()
	var center = Vector3(box_spacing, 0, box_spacing) / 2.0
	var start = start_marker.global_position + center
	box.size = Vector3(box_size, box_size, box_size)
	box_root.add_child(box)
	box.global_position = start + Vector3(pos.x * box_spacing, 0, pos.y * box_spacing)
