class_name MenuWorld
extends Node3D

@export var viewport_2d: XRToolsViewport2DIn3D

func set_viewport(v: SubViewport):
	viewport_2d.viewport = v
