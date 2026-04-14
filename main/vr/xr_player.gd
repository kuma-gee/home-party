class_name XRPlayer
extends XROrigin3D

@export var camera: XRCamera3D

func activate():
	current = true
	camera.current = true
