class_name VortexVolley
extends BaseGame

@onready var hud: VortexHUD = %VortexHUD
@onready var core: VortexCore = $VortexCore
@onready var game_manager: VortexArena = $VortexArena
@onready var ai_manager: VortexAIManager = %AIManager

const STRIKER_HAND_SCENE: PackedScene = preload("res://mods-unpacked/KumaGee-VRCore/vortex-volley/striker_hand.tscn")

## True once the VR player confirms readiness. Mobile players ready from their
## phones (A/B); the round starts when everyone is ready.
var _vr_ready := false

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	player_list.ready_changed.connect(_on_ready_changed)
	_setup_game_manager()
	_setup_vr_striker()
	ai_manager.setup(player_list, game_manager)
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
	_vr_ready = false
	if hud:
		hud.set_state("Get Ready!")
	if game_manager:
		game_manager.reset()
	if ai_manager:
		ai_manager.on_prepare_phase_entered()
	_on_ready_changed()

## Call when the VR player confirms readiness (VR HUD ready button / in-world
## trigger). Starts the round once every mobile player is ready too.
func on_vr_ready() -> void:
	if is_game_phase:
		return
	_vr_ready = true
	check_all_ready(_vr_ready)

func _on_ready_changed() -> void:
	if is_game_phase:
		return
	check_all_ready(_vr_ready)

func _on_game_phase() -> void:
	if ai_manager:
		ai_manager.on_game_phase_entered()
	if game_manager:
		game_manager.start_round()
	if hud:
		hud.set_state("GO!")

func _on_round_ended(scores: Array[Dictionary]) -> void:
	if ai_manager:
		ai_manager.stop()
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
