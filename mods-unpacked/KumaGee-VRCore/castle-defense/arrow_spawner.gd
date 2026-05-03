class_name ArrowSpawner
extends Node

var element := Arrow.Element.NONE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key = event as InputEventKey
		if key.keycode == KEY_0:
			element = Arrow.Element.NONE
		elif key.keycode == KEY_1:
			element = Arrow.Element.FIRE
		elif key.keycode == KEY_2:
			element = Arrow.Element.ICE
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_spawn_element_at_mouse(mb.position)

func _spawn_element_at_mouse(screen_pos: Vector2) -> void:
	if element not in ArrowElement.ELEMENT_SCENE:
		return

	var cam := get_viewport().get_camera_3d()
	if not cam:
		return

	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit = get_viewport().world_3d.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var scene = ArrowElement.ELEMENT_SCENE[element].instantiate()
	scene.position = hit.position
	get_tree().current_scene.add_child(scene)
