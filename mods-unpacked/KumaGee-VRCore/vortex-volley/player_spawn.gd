class_name PlayerSpawn
extends Node3D

## Owns a single arena slot for Vortex Volley: sets up the DeflectorPlayer
## (slot geometry, player name, lives, paddle color, wall blocker) and drives
## its visual/gameplay state. DeflectorPlayer itself only handles the player's
## controls; everything else about a player lives here.

const SPAWN_GROUP: StringName = &"vortex_player_spawn"
const START_LIVES: int = 3
const FLASH_DURATION: float = 0.2

@onready var marker: Marker3D = $Marker3D
@onready var deflector: DeflectorPlayer = $Marker3D/DeflectorPlayer
@onready var player_area: CSGBox3D = $Marker3D/PlayerArea
@onready var animator: AnimationPlayer = $AnimationPlayer

## Slot position around the ring, derived from this node's transform so paddles
## do not need the arena to compute their angle/radius.
var base_angle: float = 0.0
var arena_radius: float = 0.0

var controller: ClientController = null
var player_name: String = ""
var lives: int = START_LIVES
## True while a launchable orb rests on this player's paddle. A player always has
## exactly one once it respawns; launching consumes it until the orb leaves the arena.
var has_orb: bool = false
var eliminated: bool = false

var _manager: VortexArena = null
var _color: Color = Color.WHITE
## Cached wall state so `_set_blocker` only animates real transitions. Slots are
## released/re-assigned on every re-sync, which would otherwise replay "open".
var _blocker_closed: bool = true
var _blocker_state_set: bool = false

func _ready() -> void:
	var pos := marker.global_position
	base_angle = atan2(pos.z, pos.x)
	arena_radius = Vector2(pos.x, pos.z).length()
	deflector.bind(self)
	add_to_group(SPAWN_GROUP)
	release()

# ── Assignment ────────────────────────────────────────────────────────────────

## Assigns a controller to this slot and configures the paddle for play.
func assign(player: ClientController, manager: VortexArena) -> void:
	_connect_controller(player)
	_manager = manager
	player_name = player.uuid
	lives = START_LIVES
	has_orb = true
	eliminated = false
	if player is VortexAIController:
		(player as VortexAIController).bind_spawn(self, manager)
	apply_player_color()
	_revive_paddle()

## Releases this slot back to the pool (no controller, wall closed).
func release() -> void:
	_disconnect_controller()
	_manager = null
	eliminated = false
	has_orb = false
	_deactivate_paddle()

func can_launch() -> bool:
	return has_orb and not eliminated

func request_launch() -> void:
	if _manager:
		_manager.request_launch(self)

## Called by the paddle when an orb enters its goal area.
func on_orb_passed(orb: GameOrb) -> void:
	if _manager:
		_manager.on_orb_passed(self, orb)

# ── Gameplay state ────────────────────────────────────────────────────────────

func eliminate() -> void:
	if eliminated:
		return
	eliminated = true
	has_orb = false
	_deactivate_paddle()

func revive() -> void:
	eliminated = false
	_revive_paddle()

## Brief red flash when this paddle lets an orb through.
func flash_hit() -> void:
	if not deflector.paddle_material:
		return
	deflector.paddle_material.emission = Color(1.0, 0.0, 0.0)
	deflector.paddle_material.emission_energy_multiplier = 3.0
	var tw := create_tween()
	tw.tween_property(deflector.paddle_material, "emission_energy_multiplier", 0.6, FLASH_DURATION)
	tw.tween_property(deflector.paddle_material, "emission", _color, 0.0)

func set_orb_ready() -> void:
	if eliminated or not deflector.paddle_material:
		return
	deflector.paddle_material.emission_energy_multiplier = 1.2

func clear_orb_ready() -> void:
	if not deflector.paddle_material:
		return
	deflector.paddle_material.emission_energy_multiplier = 0.6

func apply_player_color() -> void:
	if not controller:
		return
	var idx := controller.get_color_idx()
	_color = PlayerList.get_color(idx) if idx >= 0 else Color.WHITE
	if deflector.paddle_material:
		deflector.paddle_material.albedo_color = _color
		deflector.paddle_material.emission = _color
		deflector.paddle_material.emission_energy_multiplier = 0.6
	var area_material := player_area.material_override as ShaderMaterial
	if area_material:
		area_material.set_shader_parameter("base_color", _color)

# ── Internals ─────────────────────────────────────────────────────────────────

func _connect_controller(player: ClientController) -> void:
	controller = player
	deflector.set_controller(player)

func _disconnect_controller() -> void:
	if controller is VortexAIController:
		(controller as VortexAIController).unbind_spawn()
	deflector.set_controller(null)
	controller = null

func _deactivate_paddle() -> void:
	_set_paddle_visible(false)
	deflector.set_active(false)
	if deflector.goal_area:
		deflector.goal_area.monitoring = false
	_set_blocker(true)
	if deflector.paddle_material:
		deflector.paddle_material.emission_energy_multiplier = 0.6

func _revive_paddle() -> void:
	_set_paddle_visible(true)
	deflector.set_active(true)
	if deflector.goal_area:
		deflector.goal_area.monitoring = true
	_set_blocker(false)

func _set_paddle_visible(active: bool) -> void:
	deflector.visible = active
	deflector.collision_layer = 1 if active else 0

## Enables/disables the slot's wall. `enabled=true` closes the wall so orbs
## bounce off an empty slot; `enabled=false` opens it to expose the paddle gap.
## The AnimationPlayer drives both the wall blend shape (visual) and the
## full-width blocker's collision shape.
func _set_blocker(enabled: bool) -> void:
	if not animator:
		return
	if _blocker_state_set and _blocker_closed == enabled:
		return
	_blocker_state_set = true
	_blocker_closed = enabled
	animator.play("RESET" if enabled else "open")
