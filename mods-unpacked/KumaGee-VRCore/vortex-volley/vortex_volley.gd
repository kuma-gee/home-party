class_name VortexVolley
extends BaseGame

@onready var hud: VortexHUD = %VortexHUD
@onready var core: VortexCore = $VortexCore
@onready var game_manager: VortexArena = $VortexArena

const STRIKER_HAND_SCENE: PackedScene = preload("res://mods-unpacked/KumaGee-VRCore/vortex-volley/striker_hand.tscn")

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	_setup_game_manager()
	_setup_vr_striker()
	LobbyServer.send_layout("joystick")

func _setup_game_manager() -> void:
	game_manager.core = core
	game_manager.round_ended.connect(_on_round_ended)
	game_manager.lives_updated.connect(_on_lives_updated)
	game_manager.speed_updated.connect(_on_speed_updated)
	game_manager.core_health_updated.connect(_on_core_health_updated)
	game_manager.time_updated.connect(_on_time_updated)

func _setup_vr_striker() -> void:
	if not xr_player:
		return
	var left := xr_player.get_node_or_null("SubViewport/XRPlayer/LeftHand") as XRController3D
	var right := xr_player.get_node_or_null("SubViewport/XRPlayer/RightHand") as XRController3D
	var player_body := xr_player.get_node_or_null("SubViewport/XRPlayer/PlayerBody") as XRToolsPlayerBody

	if player_body:
		player_body.collision_layer = 4

	if left:
		var move := XRToolsMovementDirect.new()
		move.max_speed = 1.0
		move.input_action = "primary"
		move.order = 10
		move.add_to_group("movement_providers")
		left.add_child(move)
		if player_body:
			player_body._movement_providers.append(move)
			player_body._movement_providers.sort_custom(Callable(player_body, "sort_by_order"))

	_attach_striker_hand(left)
	_attach_striker_hand(right)

func _attach_striker_hand(controller: XRController3D) -> void:
	if not controller:
		return
	var hand := STRIKER_HAND_SCENE.instantiate() as StrikerHand
	controller.add_child(hand)
	hand.orb_hit.connect(game_manager.on_orb_blocked)

func _on_prepare_phase() -> void:
	if hud:
		hud.set_state("Get Ready!")
	if game_manager:
		game_manager.reset()
	_auto_start()

func _auto_start() -> void:
	await get_tree().create_timer(5.0).timeout
	if not is_game_phase:
		_start_game()

func _on_game_phase() -> void:
	if game_manager:
		game_manager.start_round()
	if hud:
		hud.set_state("GO!")

func _on_round_ended(scores: Array[Dictionary]) -> void:
	if hud:
		hud.set_state("Round Over!")
	finish_game("Vortex Volley", func(lb): lb.set_entries(scores))

func _on_lives_updated(data: Array[Dictionary]) -> void:
	if hud:
		hud.update_lives(data)

func _on_speed_updated(speed: float) -> void:
	if hud:
		hud.update_speed(speed)

func _on_core_health_updated(hp: int) -> void:
	if hud:
		hud.update_core_health(hp)

func _on_time_updated(remaining: float) -> void:
	if hud:
		hud.update_time(remaining)

func _debug_advance() -> void:
	if is_game_phase and game_manager:
		game_manager.force_end_round()
	else:
		super._debug_advance()
