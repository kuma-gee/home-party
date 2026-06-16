class_name HideAndSeek
extends BaseGame

## Hide & Seek — Full implementation (Tasks 001-006)
## A prop hunt game where the VR player is "It" (the seeker) and mobile
## players hide as objects in a themed room.

var logger := KumaLog.new("HIDE_AND_SEEK")

## HUD scene to display on the shared screen
@export var hud_scene: PackedScene

## Scoreboard scene
@export var scoreboard_scene: PackedScene

## Props manager node path
@export_node_path("Node3D") var props_manager_path: NodePath

## Reference to the shared screen viewport
var vr_screen: XRToolsViewport2DIn3D = null

## Reference to the CameraFollow3D node (to disable following)
var camera_follow: CameraFollow3D = null

## Props manager
var props_manager: HideAndSeekProps = null

## Game manager
var game_manager: HideAndSeekGame = null

## Distract system
var distract_system: DistractSystem = null

## Number of hiders currently in the game
var hider_count: int = 0:
	set(v):
		hider_count = v
		_update_hud()

## Time remaining in the current phase
var time_remaining: float = 120.0:
	set(v):
		time_remaining = v
		_update_hud()

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	
	# Wait for the scene tree to be fully ready
	await get_tree().process_frame
	_setup_shared_screen()
	_setup_props()
	_setup_distract_system()
	_setup_game_manager()
	_setup_room()
	
	# Send hide-and-seek layout to mobile players
	LobbyServer.send_layout("hide_and_seek")

func _setup_shared_screen() -> void:
	"""Configure the shared screen with a fixed camera and HUD."""
	var xr_player = get_node_or_null("XRPlayer")
	if not xr_player:
		logger.error("Could not find XRPlayer node")
		return
	
	vr_screen = xr_player.get_node_or_null("SubViewport/CameraFollow3D/Viewport2Din3D2") as XRToolsViewport2DIn3D
	if not vr_screen:
		logger.error("Could not find Viewport2Din3D2")
		return
	
	camera_follow = xr_player.get_node_or_null("SubViewport/CameraFollow3D") as CameraFollow3D
	if camera_follow:
		camera_follow.follow_camera = false
		logger.info("Shared screen set to fixed camera angle")
	
	if hud_scene:
		vr_screen.set_scene(hud_scene)
		vr_screen.show()
		logger.info("HUD scene set on shared screen")
	
	_update_hud()

func _setup_props() -> void:
	"""Initialize the props manager and connect tag signals."""
	if props_manager_path:
		props_manager = get_node(props_manager_path) as HideAndSeekProps
	
	if props_manager:
		logger.info("Found %d props in the room" % props_manager.get_prop_count())
		
		# Connect tag signals
		props_manager.hider_found.connect(_on_hider_found)
		props_manager.wrong_tag.connect(_on_wrong_tag)
	else:
		logger.warn("No props manager found")

func _setup_distract_system() -> void:
	"""Initialize the distract sound system."""
	distract_system = DistractSystem.new()
	add_child(distract_system)

func _setup_game_manager() -> void:
	"""Initialize the game manager for mobile hiders."""
	game_manager = HideAndSeekGame.new()
	game_manager.props_manager = props_manager
	game_manager.distract_system = distract_system
	add_child(game_manager)
	
	# Connect game manager signals
	game_manager.phase_changed.connect(_on_phase_changed)
	game_manager.setup_timer_updated.connect(_on_setup_timer)
	game_manager.hunt_timer_updated.connect(_on_hunt_timer)
	game_manager.hider_joined.connect(_on_hider_joined)
	game_manager.round_ended.connect(_on_round_ended)

func _setup_room() -> void:
	"""Initialize the room for hide and seek."""
	logger.info("Hide & Seek room initialized")
	hider_count = 0
	time_remaining = 120.0

func _on_prepare_phase() -> void:
	logger.info("Prepare phase started")
	if props_manager:
		props_manager.freeze_all()
	
	# Start setup phase when players are ready
	if game_manager:
		game_manager.phase = HideAndSeekGame.Phase.SETUP

func _on_game_phase() -> void:
	logger.info("Game phase started")
	# Hunt phase is started by game manager when setup ends

func _on_phase_changed(new_phase: int) -> void:
	"""Handle game phase changes."""
	match new_phase:
		HideAndSeekGame.Phase.SETUP:
			logger.info("Setup phase started (%.0fs)" % (game_manager.setup_duration if game_manager else 8))
			# Show "Preparing..." overlay on shared screen
			_show_preparing_overlay()
		HideAndSeekGame.Phase.HUNT:
			logger.info("Hunt phase started!")
			if props_manager:
				props_manager.unfreeze_all()
			# Restore HUD
			if hud_scene:
				vr_screen.set_scene(hud_scene)
		HideAndSeekGame.Phase.ENDED:
			logger.info("Round ended")

func _on_setup_timer(time: float) -> void:
	"""Update setup timer display."""
	time_remaining = time
	_update_hud()

func _on_hunt_timer(time: float) -> void:
	"""Update hunt timer display."""
	time_remaining = time
	_update_hud()

func _on_hider_joined(hider: HideAndSeekHider) -> void:
	"""Handle a new hider joining."""
	hider_count = game_manager.get_hider_count() if game_manager else hider_count
	_update_hud()
	logger.info("Hider joined: %s (%d total)" % [hider.player_name, hider_count])

func _on_hider_found(prop: XRToolsPickable, player_name: String) -> void:
	"""Called when a hider is found."""
	hider_count = game_manager.get_hider_count() if game_manager else hider_count
	_update_hud()
	logger.info("Hider found: %s (%d remaining)" % [player_name, hider_count])
	
	# Check if all hiders are found
	if game_manager and hider_count <= 0:
		game_manager._end_round(true)  # VR wins

func _on_wrong_tag(prop: XRToolsPickable) -> void:
	"""Called when a wrong prop is tagged."""
	logger.info("Wrong tag on: %s" % prop.name)

func _on_round_ended(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary]) -> void:
	"""Called when the round ends."""
	_show_scoreboard(vr_won, vr_score, hider_scores)

func _show_preparing_overlay() -> void:
	"""Show a 'Preparing...' overlay on the shared screen during setup."""
	# For now, just update the HUD to show "Preparing..."
	if vr_screen:
		var hud = vr_screen.get_scene_instance() as HideSeekHUD
		if hud:
			hud.hider_count = hider_count
			hud.time_remaining = time_remaining

func _show_scoreboard(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary]) -> void:
	"""Show the end-of-round scoreboard."""
	if not vr_screen or not scoreboard_scene:
		return
	
	vr_screen.set_scene(scoreboard_scene)
	var scoreboard = vr_screen.get_scene_instance() as HideSeekScoreboard
	if scoreboard:
		scoreboard.show_result(vr_won, vr_score, hider_scores)

func _update_hud() -> void:
	"""Update the HUD with current state."""
	if not vr_screen:
		return
	
	var hud = vr_screen.get_scene_instance() as HideSeekHUD
	if hud:
		hud.hider_count = hider_count
		hud.time_remaining = time_remaining
		if props_manager:
			hud.found_feed = props_manager.found_feed

func _process(delta: float) -> void:
	# Game manager handles phase timers in its own _process
	pass

func start_new_round() -> void:
	"""Start a new round (play again)."""
	if game_manager:
		game_manager.reset_for_new_round()
	
	# Reset to prepare phase
	is_game_phase = false
	prepare_phase.emit()
