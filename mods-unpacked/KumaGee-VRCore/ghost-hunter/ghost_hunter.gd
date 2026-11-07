class_name GhostHunter
extends BaseGame

## GH-6: re-emitted whenever the Hunter fires the Flash Device; the GH-5
## wrist tablet listens to this to decrement the flash charge count.
signal hunter_flash_fired(origin: Vector3)

const HUNTER_SPAWN_DOOR_DISTANCE := 2.0
const FLASH_DEVICE_DOOR_OFFSET := 1.0
const FLASH_DEVICE_HEIGHT := 1.2
## Belt-holster snap zones on the player body, left and right at hip height.
const HIP_SNAP_ZONE_PATH := "res://addons/godot-xr-tools/objects/snap_zone.tscn"
const LEFT_HIP_SNAP_ZONE_POS := Vector3(-0.22, 0.98, 0.02)
const RIGHT_HIP_SNAP_ZONE_POS := Vector3(0.22, 0.98, 0.02)
const HIP_SNAP_ZONE_GRAB_DISTANCE := 0.35
const FLASH_DEVICE_GROUP := "gh_flash_device"
const LEFT_ITEM_GROUP := "gh_left_item" # GH-7 Ecto-Vacuum will holster here
## Desktop fallback: Q/E release the holstered item and spawn it at the
## simulated hand so the player can hold-grab it; if it is not picked up
## within this time it is moved back to the holster.
const DESKTOP_ITEM_SPAWN_TIMEOUT := 3.0
const KEY_LEFT_ITEM := KEY_Q
const KEY_RIGHT_ITEM := KEY_E

@export var house_variants: Array[PackedScene] = []
@export var house_container: Node3D
@export var ghost_scene: PackedScene
@export var map_layer: GhostHunterMap
@export var flash_device_scene: PackedScene
@export var bot_count_viewport: Node3D

@onready var ai_manager: GhostHunterAIManager = %AIManager

var flash_device: FlashDevice = null
## side ("left"/"right") -> holster snap zone on the player body
var holster_zones := {}
## pickable item -> the holster zone it belongs to
var _item_home := {}
## items currently spawned loose in front of the player by Q/E, awaiting pickup
var _loose_items: Array = []
var _loose_timers := {}

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
	_setup_hip_snap_zones()
	_spawn_flash_device()
	_setup_map_layer()
	ai_manager.setup(player_list, _get_hunter_position)
	_update_bot_count_visibility()


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
	_spawn_flash_device()
	ai_manager.on_prepare_phase_entered()
	_update_bot_count_visibility()


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
	_position_bot_count_viewport(door)
	logger.info("Spawned hunter outside front door at %s" % spawn_t.origin)


## Place the bot count panel next to the front door, facing the hunter spawn,
## so it works for every house variant.
func _position_bot_count_viewport(door: Marker3D) -> void:
	if not bot_count_viewport or not door:
		return
	var t := door.global_transform
	t.origin += t.basis.z * (HUNTER_SPAWN_DOOR_DISTANCE + 0.4) + t.basis.x * 2.2
	t.origin.y = 1.5
	bot_count_viewport.global_transform = t


func _on_game_phase() -> void:
	_spawn_ghosts()
	ai_manager.on_game_phase_entered()
	_update_bot_count_visibility()


func _on_clients_changed() -> void:
	_update_bot_count_visibility()
	if is_game_phase:
		_sync_ghosts()


## The bot count panel is a solo-mode affordance: it only makes sense during
## the prepare phase with no mobile players connected (same as vortex-volley).
func _update_bot_count_visibility() -> void:
	if bot_count_viewport:
		bot_count_viewport.visible = not is_game_phase and PlayerManager.playing_clients.is_empty()


func _setup_map_layer() -> void:
	if not map_layer:
		return
	map_layer.set_ghosts_getter(get_ghosts)
	map_layer.set_hunter_position_getter(_get_hunter_position)


## GH-6: belt holsters — one snap zone per side on the player body at hip
## height. Holstered items can always be grabbed out (FunctionPickup releases
## snap-zone objects on grab) and snap back when released.
func _setup_hip_snap_zones() -> void:
	for zone in holster_zones.values():
		if is_instance_valid(zone):
			zone.queue_free()
	holster_zones.clear()
	if not xr_player or not xr_player.player_body:
		logger.warn("No player body for the hip snap zones")
		return
	_make_hip_snap_zone("left", LEFT_HIP_SNAP_ZONE_POS, LEFT_ITEM_GROUP)
	_make_hip_snap_zone("right", RIGHT_HIP_SNAP_ZONE_POS, FLASH_DEVICE_GROUP)


func _make_hip_snap_zone(side: String, pos: Vector3, snap_group: String) -> void:
	var zone := load(HIP_SNAP_ZONE_PATH).instantiate() as XRToolsSnapZone
	zone.name = "HipSnapZone" + side.capitalize()
	zone.snap_require = snap_group
	zone.grab_distance = HIP_SNAP_ZONE_GRAB_DISTANCE
	# RANGE (not DROPPED): the zone must not re-snap an item the moment it is
	# dropped — Q/E desktop spawns release the item from the holster and move
	# it in front of the player in the same frame; with DROPPED mode the
	# zone's deferred dropped-handler would snap it right back. RANGE only
	# snaps items that are actually inside the grab area, and it never steals
	# a held item (can_pick_up is false while picked up). Far-away drops are
	# still returned by _on_item_dropped.
	zone.snap_mode = XRToolsSnapZone.SnapMode.RANGE
	zone.position = pos
	xr_player.player_body.add_child(zone)
	holster_zones[side] = zone


## GH-6: spawn the pickable Flash Device next to the front door (where the
## Hunter spawns), holster it into the right hip snap zone, and wire it to
## the ghost list, the shared-screen Hunter-location ping, and the GH-5
## tablet charge hook.
func _spawn_flash_device() -> void:
	if flash_device and is_instance_valid(flash_device):
		var home: XRToolsSnapZone = _item_home.get(flash_device, null)
		if is_instance_valid(home) and home.picked_up_object == flash_device:
			home.picked_up_object = null
		_item_home.erase(flash_device)
		_loose_items.erase(flash_device)
		_loose_timers.erase(flash_device)
		for zone in holster_zones.values():
			if is_instance_valid(zone):
				zone.enabled = true
		flash_device.queue_free()
		flash_device = null
	if not flash_device_scene:
		logger.warn("No flash device scene configured")
		return
	flash_device = flash_device_scene.instantiate() as FlashDevice
	if not flash_device:
		return
	var parent := house_container if house_container else self
	parent.add_child(flash_device)
	var door := house.get_front_door() if house else null
	if door:
		flash_device.global_position = door.global_position + door.global_transform.basis.z * FLASH_DEVICE_DOOR_OFFSET
		flash_device.global_position.y = FLASH_DEVICE_HEIGHT
	else:
		flash_device.global_position = Vector3(0.0, FLASH_DEVICE_HEIGHT, 0.0)
	_setup_flash_device()
	_holster_item(flash_device, "right")
	logger.info("Spawned flash device at %s" % flash_device.global_position)


func _setup_flash_device() -> void:
	if not flash_device:
		return
	flash_device.set_ghosts_getter(get_ghosts)
	flash_device.flash_fired.connect(_on_flash_fired)
	flash_device.dropped.connect(_on_item_dropped, CONNECT_DEFERRED)


## Snap an item into its side's hip holster if it is not held.
func _holster_item(item: Node3D, side: String) -> void:
	if not is_instance_valid(item) or item.is_picked_up():
		return
	var zone: XRToolsSnapZone = holster_zones.get(side, null)
	if is_instance_valid(zone) and not zone.has_snapped_object():
		_item_home[item] = zone
		zone.pick_up_object(item)


## When an item is released anywhere, snap it back to its holster. Deferred +
## is_picked_up guard: grabbing it out of the holster must not re-snap it
## while the hand is taking it. Items spawned loose by Q/E are excluded —
## their timeout in _process moves them back if never picked up.
func _on_item_dropped(what) -> void:
	if _loose_items.has(what):
		return
	if what.is_picked_up():
		return
	var home: XRToolsSnapZone = _item_home.get(what, null)
	if is_instance_valid(home) and not home.has_snapped_object():
		home.pick_up_object(what)


## Desktop fallback: Q spawns the left holster item, E the right one, in
## front of the player at the simulated hand so it can be hold-grabbed
## (LMB). If it is not picked up within DESKTOP_ITEM_SPAWN_TIMEOUT it is
## moved back to the holster.
func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not (event is InputEventKey and event.is_pressed() and not event.echo):
		return
	var side := ""
	if event.keycode == KEY_RIGHT_ITEM:
		side = "right"
	elif event.keycode == KEY_LEFT_ITEM:
		side = "left"
	if side != "" and _is_desktop_mode():
		_desktop_spawn_holster_item(side)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	for item in _loose_items.duplicate():
		if not is_instance_valid(item):
			_resolve_loose_item(item)
			continue
		if item.is_picked_up():
			# the player grabbed it — normal held rules apply from here on
			_resolve_loose_item(item)
			continue
		_loose_timers[item] -= delta
		if _loose_timers[item] <= 0.0:
			_resolve_loose_item(item)
			var home: XRToolsSnapZone = _item_home.get(item, null)
			if is_instance_valid(home) and not home.has_snapped_object():
				home.pick_up_object(item)
				logger.info("Item not picked up, moved back to the holster")


## Stop tracking a loose item and re-enable its holster zone (it was disabled
## while the item was loose so the zone's RANGE snap wouldn't grab it back).
func _resolve_loose_item(item) -> void:
	_loose_items.erase(item)
	_loose_timers.erase(item)
	var home: XRToolsSnapZone = _item_home.get(item, null)
	if is_instance_valid(home):
		home.enabled = true


func _is_desktop_mode() -> bool:
	return not XRToolsStartXR.is_xr_active() and not get_viewport().use_xr


func _desktop_spawn_holster_item(side: String) -> void:
	var zone: XRToolsSnapZone = holster_zones.get(side, null)
	if not is_instance_valid(zone) or not zone.has_snapped_object():
		logger.info("No item holstered on the %s side" % side)
		return
	var item: Node3D = zone.picked_up_object
	_loose_items.append(item)
	_loose_timers[item] = DESKTOP_ITEM_SPAWN_TIMEOUT
	_item_home[item] = zone
	# Disable the zone while the item is loose: its RANGE-mode _process would
	# otherwise re-snap the item on the next frame (the item only leaves the
	# zone's grab-area list after a physics update). Re-enabled by
	# _resolve_loose_item once the item is picked up or returned.
	zone.enabled = false
	zone.drop_object()
	item.global_position = _desktop_spawn_position(side)
	logger.info("Spawned %s in front of the player (%s side)" % [item.name, side])


## Where the simulated desktop hand (and its pickup grab area) currently is.
func _desktop_spawn_position(side: String) -> Vector3:
	var pickup: XRToolsFunctionPickup = null
	if xr_player:
		var fallback := xr_player.get_node_or_null("SubViewport/XRPlayer/DesktopVRFallback") as DesktopVRFallback
		if fallback:
			pickup = fallback._right_pickup if side == "right" else fallback._left_pickup
	if is_instance_valid(pickup):
		return pickup.global_position
	if xr_player and xr_player.camera:
		var offset := DesktopVRFallback.RIGHT_HAND_OFFSET if side == "right" else DesktopVRFallback.LEFT_HAND_OFFSET
		return xr_player.camera.global_transform * offset
	return Vector3.ZERO


func _on_flash_fired(_origin: Vector3) -> void:
	if map_layer:
		map_layer.ping_hunter(_get_hunter_position())
	hunter_flash_fired.emit(_get_hunter_position())


func _get_hunter_position() -> Vector3:
	if xr_player and xr_player.player_body:
		return xr_player.player_body.global_position
	return Vector3.ZERO


func _spawn_ghosts() -> void:
	_clear_ghosts()
	_spawn_points = house.get_ghost_spawn_points() if house else []
	_spawn_points.shuffle()
	var controllers := PlayerManager.get_active_players()
	controllers.append_array(ai_manager.get_ai_controllers())
	if house:
		var targets: Array[Vector3] = []
		for marker in house.get_task_spots() + house.get_hauntable_spots():
			targets.append(marker.global_position)
		ai_manager.set_wander_targets(targets)
	for player in controllers:
		_spawn_ghost(player)
	logger.info("Spawned %d ghost(s) at game start" % ghosts.size())


func _sync_ghosts() -> void:
	var active := PlayerManager.get_active_players()
	active.append_array(ai_manager.get_ai_controllers())
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
			if ghost.controller is GhostHunterAIController:
				(ghost.controller as GhostHunterAIController).unbind_ghost()
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
	if controller is GhostHunterAIController:
		(controller as GhostHunterAIController).bind_ghost(ghost)
	ghosts.append(ghost)
	logger.info("Spawned ghost for player %s" % controller.uuid)


func _next_spawn_point() -> Vector3:
	if not _spawn_points.is_empty():
		return _spawn_points.pop_back().global_position
	# Fallback: random spot inside the house floor (24 x 18 centered at origin).
	return Vector3(randf_range(-8.0, 8.0), 0.0, randf_range(-6.0, 6.0))
