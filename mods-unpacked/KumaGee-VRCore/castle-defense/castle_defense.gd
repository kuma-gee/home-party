extends XRToolsSceneBase

@export var menu_button: Button
@export var restart_button: Button
@export var gameover_ui: Control
@export var gameover_label: Label
@export var gate_hurtbox: HurtBox
@export var gate_zone: Area3D
@export var gate_label: Label3D
@export var player_scene: PackedScene
@export var spawn_points: Array[Node3D] = []

const GATE_MAX_HEALTH := 10

var logger := KumaLog.new("CastleDefense")

@onready var play_time: Timer = $PlayTime

func _ready() -> void:
	play_time.timeout.connect(_on_play_time_timeout)
	gate_hurtbox.died.connect(_on_gate_died)
	gate_hurtbox.health_changed.connect(_on_gate_health_changed)
	gate_zone.body_entered.connect(_on_gate_zone_body_entered)
	menu_button.pressed.connect(func(): exit_to_main_menu())
	restart_button.pressed.connect(func(): reset_scene())
	gameover_ui.hide()

func scene_loaded(_user_data = null) -> void:
	get_tree().paused = false
	LobbyServer.send_layout("joystick")

	var clients := PlayerManager.playing_clients
	logger.info("Castle Defense starting with %d players" % clients.size())

	for i in clients.size():
		var player := player_scene.instantiate() as FPSPlayer
		player.game_client = clients[i]
		player.player_num = i
		get_tree().current_scene.add_child(player)
		if i < spawn_points.size():
			player.global_transform = spawn_points[i].global_transform
		else:
			player.global_position = spawn_points[i % spawn_points.size()].global_position \
				+ Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))

	play_time.start()
	_update_gate_label()
	logger.info("Game started — %.0f seconds to survive" % play_time.wait_time)

func _on_gate_zone_body_entered(body: Node3D) -> void:
	if not body is FPSPlayer:
		return
	var player := body as FPSPlayer
	if not is_instance_valid(player.hand):
		return
	var obj := player.hand.picked_up_object
	if not is_instance_valid(obj) or not obj is Bomb:
		return
	var bomb := obj as Bomb
	logger.info("Bomb reached the gate! Dealing %d damage." % bomb.damage)
	gate_hurtbox.hit(bomb.damage)
	bomb.explode()

func _on_gate_health_changed() -> void:
	_update_gate_label()
	logger.debug("Gate health: %d" % gate_hurtbox.health)

func _update_gate_label() -> void:
	if is_instance_valid(gate_label):
		gate_label.text = "Gate: %d/%d" % [gate_hurtbox.health, GATE_MAX_HEALTH]

func _on_gate_died() -> void:
	_finish_game("Attackers stormed the gate!")

func _on_play_time_timeout() -> void:
	_finish_game("Castle survived!")

func _finish_game(message: String) -> void:
	logger.info("Game over: %s" % message)
	get_tree().paused = true
	gameover_label.text = message
	gameover_ui.show()
	play_time.stop()
