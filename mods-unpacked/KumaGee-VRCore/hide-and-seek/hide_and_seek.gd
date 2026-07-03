class_name HideAndSeek
extends BaseGame

## Hide & Seek — social deduction rework.
## The VR player is the Seeker in a museum gallery full of identical NPC
## visitors; mobile players are hiders who blend into the crowd.

@export var scoreboard_scene: PackedScene
@export var hud_scene: PackedScene
@export var vr_screen: XRToolsViewport2DIn3D
@export var npc_spawner: NpcSpawner
@export var hider_scene: PackedScene
@export var museum_gallery: Node3D

var logger := KumaLog.new("HIDE_AND_SEEK")
var game_manager: HideAndSeekGame
var seeker_tag: SeekerTag
var seeker_scan: SeekerScan
var _recentered: bool = false

var hider_count: int = 0:
	set(v):
		hider_count = v

var time_remaining: float = 90.0:
	set(v):
		time_remaining = v

var found_feed: Array[String] = []:
	set(v):
		found_feed = v

var tag_cooldown: float = 0.0:
	set(v):
		tag_cooldown = v


func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	player_list.player_created.connect(_on_player_list_player_created)
	player_list.ready_changed.connect(_on_ready_changed)

	_setup_game_manager()
	_setup_seeker()
	_recenter_vr_player()

	hider_count = 0
	time_remaining = game_manager.hunt_duration if game_manager else 90.0

	LobbyServer.send_layout("joystick")
	logger.info("Hide & Seek (social deduction) room initialized")


func _setup_game_manager() -> void:
	game_manager = HideAndSeekGame.new()
	game_manager.hider_scene = hider_scene
	if museum_gallery:
		game_manager.hider_spawn_area = museum_gallery.get_node_or_null("HiderSpawnArea")
	game_manager.npc_spawner = npc_spawner
	game_manager.interactive_locations = _collect_interactive_locations()
	add_child(game_manager)

	game_manager.phase_changed.connect(_on_phase_changed)
	game_manager.setup_timer_updated.connect(_on_setup_timer)
	game_manager.hunt_timer_updated.connect(_on_hunt_timer)
	game_manager.hider_joined.connect(_on_hider_joined)
	game_manager.hider_found.connect(_on_hider_found)
	game_manager.round_ended.connect(_on_round_ended)


func _setup_seeker() -> void:
	if not xr_player:
		logger.warn("No xr_player found; seeker controls disabled")
		return

	var right_controller := xr_player.get_node_or_null("SubViewport/XRPlayer/RightHand") as XRController3D
	var right_pointer := xr_player.get_node_or_null("SubViewport/XRPlayer/RightHand/FunctionPointer2") as XRToolsFunctionPointer
	var player_body := xr_player.get_node_or_null("SubViewport/XRPlayer/PlayerBody") as XRToolsPlayerBody

	# Move the VR body to its own collision layer so the crowd (mask = world |
	# characters) never bumps the Seeker, while the Seeker still collides with
	# the world geometry (mask stays 1, set in the shared vr_space).
	if player_body:
		player_body.collision_layer = 4

	# Right-hand tag (trigger) and scan (grip).
	if right_controller and right_pointer:
		seeker_tag = SeekerTag.new()
		right_controller.add_child(seeker_tag)
		seeker_tag.setup(right_controller, right_pointer)
		if game_manager:
			seeker_tag.hider_tagged.connect(game_manager.on_hider_tagged)
			seeker_tag.wrong_tag.connect(game_manager.on_wrong_tag)

		seeker_scan = SeekerScan.new()
		right_controller.add_child(seeker_scan)
		seeker_scan.setup(right_controller, right_pointer, Callable(game_manager, "get_hiders"), self)


func _recenter_vr_player() -> void:
	if _recentered or not museum_gallery or not xr_player:
		return
	var vr_spawn := museum_gallery.get_node_or_null("VrSpawn") as Marker3D
	if vr_spawn:
		center_player_on(vr_spawn.global_transform)
		_recentered = true


func _collect_interactive_locations() -> Array[InteractiveLocation]:
	var out: Array[InteractiveLocation] = []
	if not museum_gallery:
		return out
	_collect_locations_recursive(museum_gallery, out)
	return out


func _collect_locations_recursive(node: Node, out: Array[InteractiveLocation]) -> void:
	if node is InteractiveLocation:
		out.append(node as InteractiveLocation)
	for child in node.get_children():
		_collect_locations_recursive(child, out)


func _on_prepare_phase() -> void:
	logger.info("Prepare phase started")
	_connect_hud()
	_recenter_vr_player()
	if game_manager:
		game_manager.phase = HideAndSeekGame.Phase.SETUP
	_update_player_statuses()
	var hud := _get_hud()
	if hud:
		hud.set_game_active(true)


func _on_game_phase() -> void:
	logger.info("Game phase started")


func _on_phase_changed(new_phase: int) -> void:
	match new_phase:
		HideAndSeekGame.Phase.SETUP:
			logger.info("Setup phase started (%.0fs)" % (game_manager.setup_duration if game_manager else 10.0))
		HideAndSeekGame.Phase.HUNT:
			logger.info("Hunt phase started!")
		HideAndSeekGame.Phase.ENDED:
			logger.info("Round ended")


func _on_setup_timer(time: float) -> void:
	time_remaining = time


func _on_hunt_timer(time: float) -> void:
	time_remaining = time


func _on_hider_joined(_hider: HiderCharacter) -> void:
	hider_count = game_manager.get_hider_count() if game_manager else hider_count
	_update_player_statuses()


func _on_hider_found(hider: HiderCharacter) -> void:
	hider_count = game_manager.get_hider_count() if game_manager else hider_count
	found_feed.push_front("🎯 %s found!" % hider.player_name)
	while found_feed.size() > 5:
		found_feed.remove_at(found_feed.size() - 1)
	_update_player_statuses()


func _on_round_ended(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary]) -> void:
	_show_scoreboard(vr_won, vr_score, hider_scores)


func _show_scoreboard(vr_won: bool, vr_score: int, hider_scores: Array[Dictionary]) -> void:
	if vr_screen and scoreboard_scene:
		vr_screen.set_scene(scoreboard_scene)
		var scoreboard := vr_screen.get_scene_instance() as HideSeekScoreboard
		if scoreboard:
			scoreboard.show_result(vr_won, vr_score, hider_scores)

	# Desktop leaderboard.
	var entries: Array = []
	entries.append({"name": "VR Seeker", "score": vr_score})
	for h in hider_scores:
		entries.append({"name": h.get("name", "Unknown"), "score": h.get("score", 0)})
	if desktop_gameover:
		desktop_gameover.show_leaderboard("Hide & Seek", entries)

func _process(_delta: float) -> void:
	if seeker_tag:
		tag_cooldown = seeker_tag.cooldown_time


func _connect_hud() -> void:
	var hud := _get_hud()
	if not hud:
		return
	if not hud.start_pressed.is_connected(_on_hud_start_pressed):
		hud.start_pressed.connect(_on_hud_start_pressed)
	_on_ready_changed()


func _get_hud() -> HideSeekHUD:
	if vr_screen:
		return vr_screen.get_scene_instance() as HideSeekHUD
	return null


func _on_ready_changed() -> void:
	var hud := _get_hud()
	if hud and player_list:
		hud.update_ready(player_list.get_ready_count(), player_list.get_player_count())


func _on_hud_start_pressed() -> void:
	check_all_ready(true)


func _on_player_list_player_created(_uuid: String) -> void:
	_update_player_statuses()
	_on_ready_changed()


func _update_player_statuses() -> void:
	if not game_manager or not player_list:
		return

	var player_statuses := {}
	for entry in game_manager.get_hider_statuses():
		player_statuses[str(entry.get("name", ""))] = bool(entry.get("alive", false))

	for child in player_list.get_children():
		if child.has_method("update_hider_status"):
			child.update_hider_status(bool(player_statuses.get(child.uuid, true)))
