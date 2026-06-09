class_name PickupHand3D
extends Area3D

@export var player: Node3D

#var last_collider = null:
	#set(v):
		#if last_collider == v: return
		#
		#if last_collider and last_collider.has_method("unhover"):
			#last_collider.unhover(player)
		#
		#last_collider = v
		#
		#if last_collider and last_collider.has_method("hover"):
			#last_collider.hover(player)
#
#func _process(_delta: float) -> void:
	#var best_area = _get_facing_area()
	#last_collider = best_area

var picked_up_ranged = false
var picked_up_object: XRToolsPickable

func _get_facing_area() -> XRToolsPickable:
	var areas = get_overlapping_bodies()
	if areas.is_empty():
		return null
	
	var hand_forward = -global_transform.basis.z
	var best_area: XRToolsPickable = null
	var best_dot = -1.0
	
	for area in areas:
		var pickable = area as XRToolsPickable
		if pickable and pickable.can_pick_up(self):
			var direction_to_area = (area.global_position - global_position).normalized()
			var dot = hand_forward.dot(direction_to_area)
			
			if dot > best_dot:
				best_dot = dot
				best_area = area
	
	return best_area

func action() -> void:
	if is_instance_valid(picked_up_object):
		picked_up_object.drop()
	else:
		var area = _get_facing_area()
		if area and area.pick_up(self):
			picked_up_object = area

func drop_object():
	if not is_instance_valid(picked_up_object): return
	picked_up_object.let_go(self, Vector3.ZERO, Vector3.ZERO)
	picked_up_object = null

#func action_released() -> void:
	#var area = _get_facing_area()
	##if area:
		##area.action_released(actor)
