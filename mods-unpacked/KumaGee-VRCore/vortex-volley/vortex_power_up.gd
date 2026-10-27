class_name VortexPowerUp
extends Area3D

## A collectible power-up floating on the orb plane. It monitors only the orb
## collision layer, so VR weapons and mobile paddles never trigger it. Only a
## mobile-owned orb (one with an `owner_player`) can collect it. The node runs
## its own telegraph → active → expire lifecycle and reports the outcome to the
## arena via signals.

enum Type { DUPLICATE, TURBO, PADDLE_BOOST }
enum State { TELEGRAPH, ACTIVE, PICKED_UP, EXPIRED }

signal picked_up(orb: GameOrb)
signal expired

const ORB_COLLISION_LAYER: int = 1024

@export var type: Type = Type.DUPLICATE
## How long the spawn position is telegraphed before the power-up is collectible.
@export var telegraph_time: float = 1.5
## How long the power-up stays collectible before expiring.
@export var lifetime: float = 12.0

var state: State = State.TELEGRAPH

@onready var _active_visual: Node3D = $ActiveVisual
@onready var _telegraph_visual: Node3D = $TelegraphVisual

var _timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = ORB_COLLISION_LAYER
	body_entered.connect(_on_body_entered)
	_enter_telegraph()

func _process(delta: float) -> void:
	if state == State.TELEGRAPH:
		_timer -= delta
		if _timer <= 0.0:
			_enter_active()
	elif state == State.ACTIVE:
		_timer -= delta
		if _timer <= 0.0:
			_expire()

func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	_timer = telegraph_time
	monitoring = false
	_set_visuals(false)

func _enter_active() -> void:
	state = State.ACTIVE
	_timer = lifetime
	monitoring = true
	_set_visuals(true)

func _set_visuals(active: bool) -> void:
	if _active_visual:
		_active_visual.visible = active
	if _telegraph_visual:
		_telegraph_visual.visible = not active

func _on_body_entered(body: Node3D) -> void:
	if state != State.ACTIVE:
		return
	var orb := body as GameOrb
	if not orb or orb.is_resolved():
		return
	if not is_instance_valid(orb.owner_player):
		return
	state = State.PICKED_UP
	monitoring = false
	picked_up.emit(orb)

func _expire() -> void:
	if state != State.ACTIVE:
		return
	state = State.EXPIRED
	monitoring = false
	expired.emit()
