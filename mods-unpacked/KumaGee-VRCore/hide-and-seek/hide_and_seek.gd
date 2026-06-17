class_name HideAndSeek
extends BaseGame

## Hide & Seek — full implementation.
## A prop-hunt game where the VR player is "It" (the seeker) and mobile
## players hide as objects in a themed room.

@export var hud_scene: PackedScene
@export var scoreboard_scene: PackedScene
@export var props_manager: HideAndSeekProps
@export var vr_screen: XRToolsViewport2DIn3D
@export var camera_follow: CameraFollow3D

var logger := KumaLog.new("HIDE_AND_SEEK")
var game_manager: HideAndSeekGame
var distract_system: DistractSystem

var hider_count: int = 0:
	set(v):
		hider_count = v
		_update_hud()

var time_remaining: float = 120.0:
	set(v):
		time_remaining = v
		_update_hud()


func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)

	await get_tree().process_frame
	_setup_shared_screen()
	_setup_props()
	_setup_distract_system()
	_setup_game_manager()
	hider_count = 0
	time_remaining = 120.0

	LobbyServer.send_layout("hide_and_seek")
	logger.info("Hide & Seek room initialized")


func start_new_round() -> void:
	if game_manager:
		game_manager.reset_for_new_round()
	is_game_phase = false
	prepare_phase.emit()


func _setup_shared_screen() -> void:
	if camera_follow:
		camera_follow.follow_camera = false
		logger.info("Shared screen set to fixed camera angle")

	if vr_screen and hud_scene:
		vr_screen.set_scene(hud_scene)
		vr_screen.show()
		logger.info("HUD scene set on shared screen")

	_update_hud()


func _setup_props() -> void:
	if not props_manager:
		logger.warn("No props manager assigned")
		return

	logger.info("Found %d props in the room" % props_manager.get_prop_count())
	props_manager.hider_found.connect(_on_hider_found)
	props_manager.wrong_tag.connect(_on_wrong_tag)


func _setup_distract_system() -> void:
	distract_system = DistractSystem.new()
	add_child(distract_system)


func _setup_game_manager() -> void:
	game_manager = HideAndSeekGame.new()
	game_manager.props_manager = props_manager
	game_manager.distract_system = distract_system
	add_child(game_manager)

	game_manager.phase_changed.connect(_on_phase_changed)
	game_manager.setup_timer_updated.connect(_on_setup_timer)
	game_manager.hunt_timer_updated.connect(_on_hunt_timer)
	game_manager.hider_joined.connect(_on_hider_joined)
	game_manager.round_ended.connect(_on_round_ended)


func _on_prepare_phase() -> void:
	logger.info("Prepare phase started")
	if props_manager:
		props_manager.freeze_all()
	if game_manager:
		game_manager.phase = HideAndSeekGame.Phase.SETUP


func _on_game_phase() -> void:
	logger.info("Game phase started")


func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		HideAndSeekGame.Phase.SETUP:
			var dur := game_manager.setup_duration if game_manager else 8.0
			logger.info("Setup phase started (%.0fs)" % dur)
			_show_preparing_overlay()
		HideAndSeekGame.Phase.HUNT:
			logger.info("Hunt phase started!")
			if props_manager:
				props_manager.unfreeze_all()
			if vr_screen and hud_scene:
				vr_screen.set_scene(hud_scene)
		HideAndSeekGame.Phase.ENDED:
			logger.info("Round ended")


func _on_setup_timer(time: float) -> void:
	time_remaining = time


func _on_hunt_timer(time: float) -> void:
	time_remaining = time


func _on_hider_joined(hider: HideAndSeekHider) -> void:
	hider_count = game_manager.get_hider_count() if game_manager else hider_count
	logger.info("Hider joined: %s (%d total)" % [hider.player_name, hider_count])


func _on_hider_found(_prop: XRToolsPickable, hider_name: String) -> void:
	hider_count = game_manager.get_hider_count() if game_manager else hider_count
	logger.info("Hider found: %s (%d remaining)" % [hider_name, hider_count])

	if game_manager and hider_count <= 0:
		game_manager.end_round(true)


func _on_wrong_tag(prop: XRToolsPickable) -> void:
	logger.info("Wrong tag on: %s" % prop.name)


func _on_round_ended(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary]) -> void:
	_show_scoreboard(vr_won, vr_score, hider_scores)


func _show_preparing_overlay() -> void:
	if not vr_screen:
		return
	var hud := vr_screen.get_scene_instance() as HideSeekHUD
	if hud:
		hud.hider_count = hider_count
		hud.time_remaining = time_remaining


func _show_scoreboard(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary]) -> void:
	if not vr_screen or not scoreboard_scene:
		return

	vr_screen.set_scene(scoreboard_scene)
	var scoreboard := vr_screen.get_scene_instance() as HideSeekScoreboard
	if scoreboard:
		scoreboard.show_result(vr_won, vr_score, hider_scores)


func _update_hud() -> void:
	if not vr_screen:
		return

	var hud := vr_screen.get_scene_instance() as HideSeekHUD
	if hud:
		hud.hider_count = hider_count
		hud.time_remaining = time_remaining
		if props_manager:
			hud.found_feed = props_manager.found_feed
