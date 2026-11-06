class_name GhostHunter
extends BaseGame

const HUNTER_SPAWN_DOOR_DISTANCE := 2.0

@export var house_variants: Array[PackedScene] = []
@export var house_container: Node3D
@export var ghost_scene: PackedScene
@export var map_layer: GhostHunterMap

var logger := KumaLog.new("GHOST_HUNTER")
var house: HouseLayout = null
var ghosts: Array[GhostPlayer] = []

var _spawn_points: Array[Marker3D] = []


func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	PlayerManager.clients_changed.connect(_on_clients_changed)
	_load_random_house()
	_spawn_hunter_at_front_door()
	_setup_map_layer()


func get_ghosts() -> Array[GhostPlayer]:
	return ghosts


func _load_random_house() -> void:
	if house_variants.is_empty() or not house_container:
		logger.warn("No haunted house variants configured")
		return

	var variant: PackedScene = house_variants[randi() % house_variants.size()]
	house = variant.instantiate() as HouseLayout
	house_container.add_child(house)
	logger.info("Loaded haunted house layout: %s" % house.name)
	_activate_house_camera()


func _activate_house_camera() -> void:
	var house_cam := house.get_camera() if house else null
	if not house_cam:
		logger.warn("House layout has no camera, keeping current camera")
		return
	var active_cam := get_viewport().get_camera_3d()
	if active_cam and active_cam != house_cam:
		active_cam.current = false
	house_cam.current = true


func _on_prepare_phase() -> void:
	_spawn_hunter_at_front_door()


## GH-3: spawn the hunter outside the front door, facing it. Also updates
## spawn_transform so fall/menu resets return to the door instead of the house center.
func _spawn_hunter_at_front_door() -> void:
	var door := house.get_front_door() if house else null
	if door == null or not xr_player:
		logger.warn("Cannot spawn hunter outside front door: house/door/xr_player missing")
		return
	var spawn_t := door.global_transform
	spawn_t.origin += spawn_t.basis.z * HUNTER_SPAWN_DOOR_DISTANCE
	spawn_transform = spawn_t
	center_player_on(spawn_t)
	logger.info("Spawned hunter outside front door at %s" % spawn_t.origin)


func _on_game_phase() -> void:
	_spawn_ghosts()


func _on_clients_changed() -> void:
	if is_game_phase:
		_sync_ghosts()


func _setup_map_layer() -> void:
	if not map_layer:
		return
	map_layer.set_ghosts_getter(get_ghosts)
	map_layer.set_hunter_position_getter(_get_hunter_position)


func _get_hunter_position() -> Vector3:
	if xr_player and xr_player.player_body:
		return xr_player.player_body.global_position
	return Vector3.ZERO


func _spawn_ghosts() -> void:
	_clear_ghosts()
	_spawn_points = house.get_ghost_spawn_points() if house else []
	_spawn_points.shuffle()
	for player in PlayerManager.get_active_players():
		_spawn_ghost(player)
	logger.info("Spawned %d ghost(s) at game start" % ghosts.size())


func _sync_ghosts() -> void:
	var active := PlayerManager.get_active_players()
	for i in range(ghosts.size() - 1, -1, -1):
		var ghost := ghosts[i]
		if not is_instance_valid(ghost) or not active.has(ghost.controller):
			ghosts.remove_at(i)
			if is_instance_valid(ghost):
				ghost.queue_free()
	for player in active:
		if not _has_ghost(player):
			_spawn_ghost(player)


func _has_ghost(controller: ClientController) -> bool:
	for ghost in ghosts:
		if is_instance_valid(ghost) and ghost.controller == controller:
			return true
	return false


func _clear_ghosts() -> void:
	for ghost in ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	ghosts.clear()
	_spawn_points.clear()


func _spawn_ghost(controller: ClientController) -> void:
	if not ghost_scene or not house_container:
		logger.warn("Cannot spawn ghost: ghost_scene or house_container missing")
		return
	var ghost := ghost_scene.instantiate() as GhostPlayer
	if not ghost:
		return
	var color_idx := controller.get_color_idx()
	if color_idx < 0:
		color_idx = ghosts.size()
	house_container.add_child(ghost)
	ghost.setup(controller, PlayerList.get_color(color_idx), _next_spawn_point())
	ghosts.append(ghost)
	logger.info("Spawned ghost for player %s" % controller.uuid)


func _next_spawn_point() -> Vector3:
	if not _spawn_points.is_empty():
		return _spawn_points.pop_back().global_position
	# Fallback: random spot inside the house floor (24 x 18 centered at origin).
	return Vector3(randf_range(-8.0, 8.0), 0.0, randf_range(-6.0, 6.0))
