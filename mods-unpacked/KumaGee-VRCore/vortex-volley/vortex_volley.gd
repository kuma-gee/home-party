class_name VortexVolley
extends BaseGame

@onready var hud: VortexHUD = %VortexHUD
@onready var core: VortexCore = %VortexCore
@onready var game_manager: VortexArena = %VortexArena
@onready var ai_manager: VortexAIManager = %AIManager
@export var bot_count_viewport: Node3D

const SHIELD_SCENE: PackedScene = preload("res://mods-unpacked/KumaGee-VRCore/vortex-volley/vortex_shield.tscn")
const SABER_SCENE: PackedScene = preload("res://mods-unpacked/KumaGee-VRCore/vortex-volley/vortex_saber.tscn")

## Distance from the VR player beyond which a dropped weapon respawns next to
## the player on its assigned side.
const WEAPON_RESPAWN_DISTANCE: float = 3.0

## True once the VR player confirms readiness. Mobile players ready from their
## phones (A/B); the round starts when everyone is ready.
var _vr_ready := false
var _tutorial: VortexTutorial
var _left_controller: XRController3D
var _right_controller: XRController3D
var _left_weapon: VortexWeapon
var _right_weapon: VortexWeapon
var _left_selection: VortexWeapon.Weapon = VortexWeapon.Weapon.SHIELD
var _right_selection: VortexWeapon.Weapon = VortexWeapon.Weapon.SABER

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	player_list.ready_changed.connect(_on_ready_changed)
	PlayerManager.clients_changed.connect(_update_bot_count_visibility)
	_setup_game_manager()
	_setup_vr_weapons()
	ai_manager.setup(player_list, game_manager)
	LobbyServer.send_layout("joystick")
	_update_bot_count_visibility()

## The bot count panel is a solo-mode affordance: it only makes sense during
## the prepare phase with no mobile players connected (same as castle defense).
func _update_bot_count_visibility() -> void:
	if bot_count_viewport:
		bot_count_viewport.visible = not is_game_phase and PlayerManager.playing_clients.is_empty()

func _setup_game_manager() -> void:
	game_manager.core = core
	game_manager.round_ended.connect(_on_round_ended)
	game_manager.lives_updated.connect(_on_lives_updated)
	game_manager.speed_updated.connect(_on_speed_updated)
	game_manager.core_health_updated.connect(_on_core_health_updated)
	game_manager.time_updated.connect(_on_time_updated)

func _setup_vr_weapons() -> void:
	if not xr_player:
		return
	_left_controller = xr_player.get_node_or_null("SubViewport/XRPlayer/LeftHand") as XRController3D
	_right_controller = xr_player.get_node_or_null("SubViewport/XRPlayer/RightHand") as XRController3D
	var player_body := xr_player.get_node_or_null("SubViewport/XRPlayer/PlayerBody") as XRToolsPlayerBody

	if player_body:
		player_body.collision_layer = 4

	if _left_controller:
		var move := XRToolsMovementDirect.new()
		move.max_speed = 1.0
		move.input_action = "primary"
		move.order = 10
		move.add_to_group("movement_providers")
		_left_controller.add_child(move)
		if player_body:
			player_body._movement_providers.append(move)
			player_body._movement_providers.sort_custom(Callable(player_body, "sort_by_order"))

	_apply_weapon_selection()

func _on_weapons_changed(left: VortexWeapon.Weapon, right: VortexWeapon.Weapon) -> void:
	_left_selection = left
	_right_selection = right
	_apply_weapon_selection()

func _apply_weapon_selection() -> void:
	_left_weapon = _sync_hand_weapon(_left_controller, _left_weapon, _left_selection)
	_right_weapon = _sync_hand_weapon(_right_controller, _right_weapon, _right_selection)

## Ensures [param controller] holds a weapon matching [param kind], swapping the
## held weapon when the selection changes.
func _sync_hand_weapon(controller: XRController3D, current: VortexWeapon, kind: VortexWeapon.Weapon) -> VortexWeapon:
	if is_instance_valid(current) and _weapon_matches(current, kind):
		return current
	if is_instance_valid(current):
		current.drop_and_free()
	return _spawn_weapon(controller, kind)

func _weapon_matches(weapon: VortexWeapon, kind: VortexWeapon.Weapon) -> bool:
	if kind == VortexWeapon.Weapon.SHIELD:
		return weapon is VortexShield
	return weapon is VortexSaber

## Spawns the weapon for [param kind] and grabs it into [param controller]'s
## FunctionPickup, then wires its block/slice signals to the arena.
func _spawn_weapon(controller: XRController3D, kind: VortexWeapon.Weapon) -> VortexWeapon:
	if not controller:
		return null
	var scene := SHIELD_SCENE if kind == VortexWeapon.Weapon.SHIELD else SABER_SCENE
	var weapon := scene.instantiate() as VortexWeapon
	if not weapon:
		return null
	# Stay held without holding grip; weapons are dropped only when swapped.
	weapon.press_to_hold = false
	add_child(weapon)
	weapon.global_position = controller.global_position
	var pickup := controller.get_node_or_null("FunctionPickup") as XRToolsFunctionPickup
	if pickup:
		# Auto-equip via the pickup's grab path so the object is properly held.
		pickup._pick_up_object(weapon)
	if not weapon.orb_hit.is_connected(game_manager.on_orb_blocked):
		weapon.orb_hit.connect(game_manager.on_orb_blocked)
	if not weapon.orb_sliced.is_connected(game_manager.on_orb_sliced):
		weapon.orb_sliced.connect(game_manager.on_orb_sliced)
	return weapon

func _physics_process(_delta: float) -> void:
	_check_weapon_respawn(_left_controller, _left_weapon)
	_check_weapon_respawn(_right_controller, _right_weapon)

## Respawns a dropped [param weapon] next to [param controller] once it is too
## far from the VR player to grab again.
func _check_weapon_respawn(controller: XRController3D, weapon: VortexWeapon) -> void:
	if not is_instance_valid(weapon) or not controller:
		return
	if weapon.is_picked_up():
		return
	if not xr_player or not xr_player.origin:
		return
	if weapon.global_position.distance_to(xr_player.origin.global_position) <= WEAPON_RESPAWN_DISTANCE:
		return
	weapon.linear_velocity = Vector3.ZERO
	weapon.angular_velocity = Vector3.ZERO
	weapon.global_position = controller.global_position

func _on_prepare_phase() -> void:
	_vr_ready = false
	_show_tutorial()
	if hud:
		hud.set_state("Get Ready!")
	if game_manager:
		game_manager.reset()
	if ai_manager:
		ai_manager.on_prepare_phase_entered()
	_update_bot_count_visibility()
	_on_ready_changed()

func _show_tutorial() -> void:
	if not vr_screen:
		return
	_tutorial = vr_screen.get_scene_instance() as VortexTutorial
	if not is_instance_valid(_tutorial):
		vr_screen.set_scene(vr_screen.scene)
		_tutorial = vr_screen.get_scene_instance() as VortexTutorial
	if is_instance_valid(_tutorial):
		if not _tutorial.ready_pressed.is_connected(on_vr_ready):
			_tutorial.ready_pressed.connect(on_vr_ready)
		var weapon_select := _tutorial.weapon_select
		if is_instance_valid(weapon_select):
			if not weapon_select.weapons_changed.is_connected(_on_weapons_changed):
				weapon_select.weapons_changed.connect(_on_weapons_changed)
			_on_weapons_changed(weapon_select.selected_left, weapon_select.selected_right)
	vr_screen.show()

func _update_tutorial_ready() -> void:
	if is_instance_valid(_tutorial):
		_tutorial.update_ready(player_list.get_ready_count(), player_list.get_player_count())

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
	_update_tutorial_ready()
	check_all_ready(_vr_ready)

func _on_game_phase() -> void:
	if vr_screen:
		vr_screen.hide()
	_update_bot_count_visibility()
	_apply_weapon_selection()
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
	for entry in data:
		var player_ui := player_list.find_existing_node(str(entry.get("uuid", ""))) as VortexVolleyPlayerUI
		if player_ui:
			player_ui.set_lives(int(entry.get("lives", 0)))

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
