@tool
extends MeshInstance3D

## Highlight ring that only lights up while the snapped item is held in a
## player's hand, and hides again the moment it is dropped (whether back into
## the snap zone or anywhere else).

var _tracked_item: Node3D = null


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false

	var snap_zone := get_parent()
	if snap_zone and snap_zone.has_signal("has_picked_up"):
		snap_zone.has_picked_up.connect(_on_snap_has_picked_up)
	if snap_zone and snap_zone.has_signal("has_dropped"):
		snap_zone.has_dropped.connect(_on_snap_has_dropped)

	if snap_zone and snap_zone.has_method("has_snapped_object") and snap_zone.has_snapped_object():
		_track_item(snap_zone.picked_up_object)


func _track_item(item: Node3D) -> void:
	_untrack_item()
	_tracked_item = item
	if is_instance_valid(_tracked_item):
		_tracked_item.grabbed.connect(_on_item_grabbed)
		_tracked_item.dropped.connect(_on_item_dropped)


func _untrack_item() -> void:
	if is_instance_valid(_tracked_item):
		if _tracked_item.grabbed.is_connected(_on_item_grabbed):
			_tracked_item.grabbed.disconnect(_on_item_grabbed)
		if _tracked_item.dropped.is_connected(_on_item_dropped):
			_tracked_item.dropped.disconnect(_on_item_dropped)
	_tracked_item = null


func _on_snap_has_picked_up(what: Node3D) -> void:
	_track_item(what)
	visible = false


func _on_snap_has_dropped() -> void:
	visible = false


func _on_item_grabbed(_pickable, by: Node3D) -> void:
	# Only light up when a hand takes the item away, not when the snap-zone
	# itself is the one holding it (e.g. initial equip / auto re-snap).
	visible = not (by is XRToolsSnapZone)


func _on_item_dropped(_pickable) -> void:
	visible = false
