class_name XRToolsSceneBase
extends Node3D

## XR Tools Scene Base Class
##
## This is our base scene for all our levels.  It ensures that we have all bits
## in place to load our scene into our staging scene.
##
## Developers can customize scene transitions by extending from this class and
## overriding the [method scene_loaded] behavior.
signal request_exit_to_main_menu
signal request_load_scene(p_scene_path, user_data)
signal request_reset_scene(user_data)
signal request_quit

signal scene_loaded_finish


@export var xr_player: VRSpace
@export var bgm_audio: AudioStream

var spawn_transform: Transform3D

func _ready() -> void:
	if xr_player == null:
		xr_player = get_node("VRSpace")

func reset_player_space(offset: Vector3 = Vector3.ZERO):
	var origin = spawn_transform
	origin.origin += offset
	center_player_on(origin)

## This method center the player on the [param p_transform] transform.
func center_player_on(p_transform : Transform3D):
	# In order to center our player so the players feet are at the location
	# indicated by p_transform, and having our player looking in the required
	# direction, we must offset this transform using the cameras transform.
	# So we get our current camera transform in local space
	xr_player.camera.transform.origin.x = 0
	xr_player.camera.transform.origin.z = 0
	var camera_transform = xr_player.camera.transform

	# We obtain our view direction and zero out our height
	var view_direction = camera_transform.basis.z
	view_direction.y = 0

	# Now create the transform that we will use to offset our input with
	var transform : Transform3D
	transform = transform.looking_at(-view_direction, Vector3.UP)
	transform.origin = camera_transform.origin
	transform.origin.y = 0

	# And now update our origin point
	xr_player.origin.global_transform = (p_transform * transform.inverse()).orthonormalized()

	# If we have a player body, we need to set its starting position too.
	var player_body : XRToolsPlayerBody = XRToolsPlayerBody.find_instance(xr_player.origin)
	if player_body:
		player_body.global_transform = p_transform


func scene_loaded(user_data = null):
	spawn_transform = xr_player.origin.global_transform
	xr_player.center_player.connect(reset_player_space)
	center_player_on(spawn_transform)
	scene_loaded_finish.emit()


func scene_visible(user_data = null):
	pass


func scene_pre_exiting(user_data = null):
	pass


func scene_exiting(user_data = null):
	xr_player.center_player.disconnect(reset_player_space)


func exit_to_main_menu() -> void:
	emit_signal("request_exit_to_main_menu")


func load_scene(p_scene_path : String, user_data = null) -> void:
	print("loading scene: %s" % p_scene_path)
	emit_signal("request_load_scene", p_scene_path, user_data)


func reset_scene(user_data = null) -> void:
	emit_signal("request_reset_scene", user_data)


func quit() -> void:
	emit_signal("request_quit")
