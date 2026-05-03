extends Node3D

@export var arrow_scene: PackedScene
@export var snap_zone: XRToolsSnapZone

var arrow: Node3D
var is_exiting := false

func _ready() -> void:
	snap_zone.has_picked_up.connect(func(_p): _check_snap_object())
	snap_zone.tree_exiting.connect(func(): is_exiting = true)
	snap_zone.has_dropped.connect(func(): _check_snap_object())
	_check_snap_object()

func _check_snap_object():
	if is_exiting or not snap_zone.is_inside_tree() or not is_inside_tree(): return
	
	if snap_zone.has_snapped_object():
		if arrow != snap_zone.picked_up_object:
			arrow.queue_free()
			arrow = snap_zone.picked_up_object
		return
	
	arrow = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	snap_zone.pick_up_object(arrow)
