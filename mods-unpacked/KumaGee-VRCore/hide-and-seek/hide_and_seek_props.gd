class_name HideAndSeekProps
extends Node3D

## Manages all props in the Hide & Seek room.
## Tracks initial positions for round reset, handles prop physics state, and tagging.

signal hider_found(prop: XRToolsPickable, player_name: String)
signal wrong_tag(prop: XRToolsPickable)
signal stun_started()
signal stun_ended()

## Duration of the stun when tagging a static prop (seconds)
@export var stun_duration: float = 2.0

## Reference to the XRPlayer for accessing hands/pickups
@export var xr_player: NodePath

## Found feed entries (most recent first)
var found_feed: Array[String] = []

## Whether the VR player is currently stunned
var is_stunned: bool = false:
	set(v):
		is_stunned = v
		if v:
			stun_started.emit()
		else:
			stun_ended.emit()

## Stun timer
var _stun_timer: float = 0.0

## Initial transforms for all props (saved for reset)
var _initial_transforms: Dictionary = {}  # Node -> Transform3D

## All props in the room
var _props: Array[XRToolsPickable] = []

## Props that are hiders (controlled by mobile players)
var _hider_props: Dictionary = {}  # XRToolsPickable -> String (player name)

## FunctionPickup references for both hands
var _left_pickup: XRToolsFunctionPickup = null
var _right_pickup: XRToolsFunctionPickup = null

func _ready() -> void:
	_collect_props()
	_save_initial_positions()
	_connect_tag_signals()
	_setup_pickups()

func _collect_props() -> void:
	"""Collect all XRToolsPickable props in the scene tree."""
	_props.clear()
	_find_pickables(self)

func _find_pickables(node: Node) -> void:
	for child in node.get_children():
		if child is XRToolsPickable:
			_props.append(child as XRToolsPickable)
		_find_pickables(child)

func _save_initial_positions() -> void:
	"""Save the initial transform of each prop for round reset."""
	_initial_transforms.clear()
	for prop in _props:
		_initial_transforms[prop] = prop.global_transform

func _connect_tag_signals() -> void:
	"""Connect to all props' action_pressed signals for tagging."""
	for prop in _props:
		if prop.has_signal("action_pressed"):
			prop.action_pressed.connect(_on_prop_action_pressed.bind(prop))

func _setup_pickups() -> void:
	"""Find the FunctionPickup nodes on both hands."""
	if xr_player:
		var xr = get_node(xr_player)
		if xr:
			_left_pickup = xr.get_node_or_null("SubViewport/XRPlayer/LeftHand/FunctionPickup") as XRToolsFunctionPickup
			_right_pickup = xr.get_node_or_null("SubViewport/XRPlayer/RightHand/FunctionPickup") as XRToolsFunctionPickup

func _on_prop_action_pressed(_pickable, prop: XRToolsPickable) -> void:
	"""Called when the VR player pulls the trigger while holding a prop."""
	if is_stunned:
		return
	
	var is_hider = _hider_props.has(prop)
	
	if is_hider:
		_handle_correct_tag(prop)
	else:
		_handle_wrong_tag(prop)

func _handle_correct_tag(prop: XRToolsPickable) -> void:
	"""Handle a correct tag (hider found)."""
	print("[Props] Correct tag! Hider found: %s" % prop.name)
	
	# Get player name
	var player_name = _hider_props.get(prop, "Unknown")
	
	# Drop the prop first
	prop.drop()
	
	# Mark as found (hide and disable)
	prop.visible = false
	prop.enabled = false
	prop.collision_layer = 0
	prop.collision_mask = 0
	prop.freeze = true
	
	# Add to found feed
	found_feed.push_front("🎯 %s found!" % player_name)
	if found_feed.size() > 5:
		found_feed.resize(5)
	
	# Notify listeners
	hider_found.emit(prop, player_name)
	
	# VR player is NOT stunned for correct tags (it's a reward)

func _handle_wrong_tag(prop: XRToolsPickable) -> void:
	"""Handle a wrong tag (static prop)."""
	print("[Props] Wrong tag! Stunned for %.1fs" % stun_duration)
	
	# Drop the prop
	prop.drop()
	
	# Start stun
	is_stunned = true
	_stun_timer = stun_duration
	
	# Disable pickups during stun
	_disable_pickups()
	
	# Notify listeners
	wrong_tag.emit(prop)

func _disable_pickups() -> void:
	"""Disable both hand pickups during stun."""
	if _left_pickup:
		_left_pickup.enabled = false
	if _right_pickup:
		_right_pickup.enabled = false

func _reenable_pickups() -> void:
	"""Re-enable both hand pickups after stun ends."""
	if _left_pickup:
		_left_pickup.enabled = true
	if _right_pickup:
		_right_pickup.enabled = true

func _process(delta: float) -> void:
	if is_stunned:
		_stun_timer -= delta
		if _stun_timer <= 0:
			is_stunned = false
			_reenable_pickups()

func mark_as_hider(prop: XRToolsPickable, player_name: String) -> void:
	"""Mark a prop as controlled by a mobile hider."""
	_hider_props[prop] = player_name

func unmark_hider(prop: XRToolsPickable) -> void:
	"""Remove hider mark from a prop."""
	_hider_props.erase(prop)

func unfreeze_all() -> void:
	"""Unfreeze all props so they become physics bodies."""
	for prop in _props:
		if not _hider_props.has(prop):  # Don't unfreeze hider props (they're controlled by mobile)
			prop.freeze = false

func freeze_all() -> void:
	"""Freeze all props (used during setup phase)."""
	for prop in _props:
		prop.freeze = true

func reset_all() -> void:
	"""Reset all props to their initial positions and freeze them."""
	for prop in _props:
		if _initial_transforms.has(prop):
			prop.global_transform = _initial_transforms[prop]
		prop.freeze = true
		prop.visible = true
		prop.enabled = true
		prop.collision_layer = 5
		prop.collision_mask = 1
		prop.linear_velocity = Vector3.ZERO
		prop.angular_velocity = Vector3.ZERO
	
	_hider_props.clear()
	found_feed.clear()
	is_stunned = false
	_stun_timer = 0.0
	_reenable_pickups()

func get_props() -> Array[XRToolsPickable]:
	"""Get all props in the room."""
	return _props.duplicate()

func get_prop_count() -> int:
	"""Get the number of props in the room."""
	return _props.size()

func get_hider_count() -> int:
	"""Get the number of hider props."""
	return _hider_props.size()
