class_name HideAndSeekProps
extends Node3D

## Manages all props in the Hide & Seek room.
## Tracks initial positions for round reset, handles prop physics state, and tagging.

signal hider_found(prop: XRToolsPickable, player_name: String)
signal wrong_tag(prop: XRToolsPickable)
signal stun_started()
signal stun_ended()

@export var stun_duration: float = 2.0
@export var left_pickup: XRToolsFunctionPickup
@export var right_pickup: XRToolsFunctionPickup

var found_feed: Array[String] = []
var is_stunned: bool = false:
	set(v):
		is_stunned = v
		if v:
			stun_started.emit()
		else:
			stun_ended.emit()

var _stun_timer: float = 0.0
var _initial_transforms: Dictionary = {}  ## Node -> Transform3D
var _props: Array[XRToolsPickable] = []
var _hider_props: Dictionary = {}  ## XRToolsPickable -> String (player name)


func _ready() -> void:
	_collect_props()
	_save_initial_positions()
	_connect_tag_signals()


func _process(delta: float) -> void:
	if is_stunned:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			is_stunned = false
			_reenable_pickups()


func mark_as_hider(prop: XRToolsPickable, player_name: String) -> void:
	_hider_props[prop] = player_name


func unmark_hider(prop: XRToolsPickable) -> void:
	_hider_props.erase(prop)


func unfreeze_all() -> void:
	for prop in _props:
		if not _hider_props.has(prop):
			prop.freeze = false


func freeze_all() -> void:
	for prop in _props:
		prop.freeze = true


func reset_all() -> void:
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
	return _props.duplicate()


func get_prop_count() -> int:
	return _props.size()


func get_hider_count() -> int:
	return _hider_props.size()


func get_initial_transform(prop: XRToolsPickable) -> Transform3D:
	if _initial_transforms.has(prop):
		return _initial_transforms[prop]
	return prop.global_transform


func _collect_props() -> void:
	_props.clear()
	_find_pickables(self)


func _find_pickables(node: Node) -> void:
	for child in node.get_children():
		if child is XRToolsPickable:
			_props.append(child as XRToolsPickable)
		_find_pickables(child)


func _save_initial_positions() -> void:
	_initial_transforms.clear()
	for prop in _props:
		_initial_transforms[prop] = prop.global_transform


func _connect_tag_signals() -> void:
	for prop in _props:
		if prop.has_signal("action_pressed"):
			prop.action_pressed.connect(_on_prop_action_pressed.bind(prop))


func _on_prop_action_pressed(_pickable, prop: XRToolsPickable) -> void:
	if is_stunned:
		return

	if _hider_props.has(prop):
		_handle_correct_tag(prop)
	else:
		_handle_wrong_tag(prop)


func _handle_correct_tag(prop: XRToolsPickable) -> void:
	var player_name: String = _hider_props.get(prop, "Unknown")
	print("[Props] Correct tag! Hider found: %s" % player_name)

	prop.drop()
	prop.visible = false
	prop.enabled = false
	prop.collision_layer = 0
	prop.collision_mask = 0
	prop.freeze = true

	found_feed.push_front("🎯 %s found!" % player_name)
	if found_feed.size() > 5:
		found_feed.resize(5)

	hider_found.emit(prop, player_name)


func _handle_wrong_tag(prop: XRToolsPickable) -> void:
	print("[Props] Wrong tag! Stunned for %.1fs" % stun_duration)
	prop.drop()
	is_stunned = true
	_stun_timer = stun_duration
	_disable_pickups()
	wrong_tag.emit(prop)


func _disable_pickups() -> void:
	if left_pickup:
		left_pickup.enabled = false
	if right_pickup:
		right_pickup.enabled = false


func _reenable_pickups() -> void:
	if left_pickup:
		left_pickup.enabled = true
	if right_pickup:
		right_pickup.enabled = true
