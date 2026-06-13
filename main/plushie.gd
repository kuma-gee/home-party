@tool
extends XRToolsPickable

enum State { CONNECTED, UNPLAYABLE }

const PLACEHOLDER_SQUEAK := preload("res://assets/sound/sfx/pickup.mp3")

static var _model_offset := -1

@onready var models: Node3D = $Models
@onready var player_tag: Label3D = $PlayerTag
@onready var squeak_player: AudioStreamPlayer3D = $SqueakPlayer
@onready var unplayable_icon: Node3D = $UnplayableIcon

var player_uuid: String
var player_index: int
var _visible_animal: Node3D
var _glow_materials: Array[StandardMaterial3D] = []
var _player_color: Color
var _client_controller: ClientController
var _state := State.CONNECTED


func setup(idx: int, uuid: String, color: Color, controller: ClientController) -> void:
	player_index = idx
	player_uuid = uuid
	_player_color = color
	_client_controller = controller
	name = "Plushie%s" % idx

	player_tag.text = "P%d" % (idx + 1)
	player_tag.modulate = color

	if _model_offset == -1:
		_model_offset = randi()

	for child in models.get_children():
		child.visible = false

	var count = models.get_child_count()
	var animal = models.get_child((idx + _model_offset) % count)
	animal.visible = true
	_visible_animal = animal

	_setup_glow_materials(animal, color)

	squeak_player.stream = PLACEHOLDER_SQUEAK

	if _client_controller:
		_client_controller.primary_action_pressed.connect(_on_primary_action)
		_client_controller.secondary_action_pressed.connect(_on_secondary_action)


func _setup_glow_materials(animal: Node3D, color: Color) -> void:
	_glow_materials.clear()
	for mesh_instance in _find_mesh_instances(animal):
		var mesh = mesh_instance.mesh
		if not mesh:
			continue
		for i in mesh.get_surface_count():
			var mat := mesh_instance.get_surface_override_material(i)
			if not mat:
				mat = mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				mat = mat.duplicate()
				mat.emission_enabled = true
				mat.emission = color
				mat.emission_energy_multiplier = 0.0
				mesh_instance.set_surface_override_material(i, mat)
				_glow_materials.append(mat)


static func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		for m in _find_mesh_instances(child):
			result.append(m)
	return result


func _on_primary_action() -> void:
	_squeak_and_glow()


func _on_secondary_action() -> void:
	_squeak_and_glow(1.3)


func _squeak_and_glow(pitch_scale := 1.0) -> void:
	squeak_player.pitch_scale = randf_range(0.9, 1.1) * pitch_scale
	squeak_player.play()

	var tween = create_tween().set_parallel(true)

	if _visible_animal:
		tween.tween_property(_visible_animal, "scale", Vector3(1.2, 0.7, 1.2), 0.08)
		tween.tween_property(_visible_animal, "scale", Vector3.ONE, 0.25).set_delay(0.08)

	tween.set_parallel(false)
	tween.tween_method(_set_glow_intensity, 0.0, 1.0, 0.12)
	tween.tween_method(_set_glow_intensity, 1.0, 0.0, 0.3)


func _set_glow_intensity(value: float) -> void:
	for mat in _glow_materials:
		mat.emission_energy_multiplier = value


func set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	match _state:
		State.UNPLAYABLE:
			unplayable_icon.visible = true
		State.CONNECTED:
			unplayable_icon.visible = false


func evaluate_unplayable(game: GameResource) -> void:
	if not _client_controller or _client_controller.active == false:
		return
	if game and game.phone_only and _client_controller is GamepadController:
		set_state(State.UNPLAYABLE)
	else:
		set_state(State.CONNECTED)


func get_visible_model() -> String:
	for child in models.get_children():
		if child.visible:
			return child.name
	return ""


func _exit_tree() -> void:
	if _client_controller:
		if _client_controller.primary_action_pressed.is_connected(_on_primary_action):
			_client_controller.primary_action_pressed.disconnect(_on_primary_action)
		if _client_controller.secondary_action_pressed.is_connected(_on_secondary_action):
			_client_controller.secondary_action_pressed.disconnect(_on_secondary_action)
