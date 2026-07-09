class_name VortexVolley
extends BaseGame

@export var deflector_scene: PackedScene
@export var orb_scene: PackedScene

@onready var hud: VortexHUD = %VortexHUD

var game_manager: VortexVolleyGame
var vr_striker: VRStriker

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	_setup_arena()
	_setup_game_manager()
	_setup_vr_striker()
	LobbyServer.send_layout("joystick")

func _setup_arena() -> void:
	var arena := VortexArena.new()
	add_child(arena)

func _setup_game_manager() -> void:
	game_manager = VortexVolleyGame.new()
	game_manager.deflector_scene = deflector_scene
	game_manager.orb_scene = orb_scene
	add_child(game_manager)
	game_manager.round_ended.connect(_on_round_ended)
	game_manager.lives_updated.connect(_on_lives_updated)

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

	vr_striker = VRStriker.new()
	add_child(vr_striker)
	vr_striker.setup(left, right)
	if game_manager:
		vr_striker.orb_hit.connect(game_manager.on_orb_hit_by_vr)

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

func _debug_advance() -> void:
	if is_game_phase and game_manager:
		game_manager.force_end_round()
	else:
		super._debug_advance()
