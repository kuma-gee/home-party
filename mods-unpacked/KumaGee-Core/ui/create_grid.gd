extends Node

@export var camera: Camera3D
@export var block_scene: PackedScene

@export_category("Grid")
@export var grid_spacing := 1.0

var grid_size = 0
var spacing = 0

func _setup_floor_and_walls():
	var floor_box = _create_box()
	floor_box.size.x = grid_size * spacing
	floor_box.size.z = grid_size * spacing
	
	var offset = -spacing / 2.0
	floor_box.position.x = offset
	floor_box.position.z = offset

	var east_wall = _create_box()
	var west_wall = _create_box()
	var north_wall = _create_box()
	var south_wall = _create_box()
	east_wall.hide()
	west_wall.hide()
	north_wall.hide()
	south_wall.hide()

	east_wall.rotation.z = deg_to_rad(-90)
	west_wall.rotation.z = deg_to_rad(-90)
	north_wall.rotation.z = deg_to_rad(-90)
	north_wall.rotation.x = deg_to_rad(90)
	south_wall.rotation.z = deg_to_rad(-90)
	south_wall.rotation.x = deg_to_rad(90)

	east_wall.size.z = grid_size * spacing
	west_wall.size.z = grid_size * spacing
	north_wall.size.z = grid_size * spacing
	south_wall.size.z = grid_size * spacing

	east_wall.position.x = (grid_size * spacing) / 2.0 + (east_wall.size.y / 2.0) + offset
	east_wall.position.z = offset
	west_wall.position.x = -((grid_size * spacing) / 2.0 + (west_wall.size.y / 2.0) - offset)
	west_wall.position.z = offset
	north_wall.position.z = -((grid_size * spacing) / 2.0 + (north_wall.size.y / 2.0) - offset)
	north_wall.position.x = offset
	south_wall.position.z = (grid_size * spacing) / 2.0 + (south_wall.size.y / 2.0) + offset
	south_wall.position.x = offset

func _create_box():
	var b = CSGBox3D.new()
	b.size.y = 0.2
	b.use_collision = true
	add_child(b)
	return b

func create_grid(size):
	grid_size = size
	spacing = grid_spacing
	var blocks := []
	for x in range(grid_size):
		for z in range(grid_size):
			var block = block_scene.instantiate() as Node3D
			block.position = Vector3(
				(x - grid_size / 2.0) * spacing,
				0.0,
				(z - grid_size / 2.0) * spacing
			)
			add_child(block)
			blocks.append(block)
	
	_setup_floor_and_walls()
	_position_camera()

	return blocks

func get_random_position(exclude := []):
	var grid_pos = _get_random_grid_position(exclude)
	return Vector3(
		(grid_pos.x - grid_size / 2.0) * spacing,
		0.5,  # Slightly above the grid
		(grid_pos.y - grid_size / 2.0) * spacing
	)

func _get_random_grid_position(used_positions: Array) -> Vector2i:
	var max_attempts = 100
	var attempts = 0
	
	while attempts < max_attempts:
		var x = randi() % grid_size
		var z = randi() % grid_size
		var pos = Vector2i(x, z)
		
		if pos not in used_positions:
			return pos
		
		attempts += 1
	
	# Fallback: return any position if all attempts failed
	return Vector2i(randi() % grid_size, randi() % grid_size)

func _position_camera():
	if not camera:
		return
	
	var grid_world_size = grid_size * spacing
	var fov_rad = deg_to_rad(camera.fov)
	var distance = (grid_world_size / 2.0) / tan(fov_rad / 2.0)
	
	distance *= 1.5
	
	var angle = deg_to_rad(60)
	camera.position = Vector3(0, distance * sin(angle), distance * cos(angle))
	camera.look_at(Vector3.ZERO, Vector3.UP)
