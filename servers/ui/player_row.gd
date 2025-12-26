class_name PlayerRow
extends Control

@export var label: Label
@export var texture_rect: TextureRect



func set_text(txt):
	label.text = "%s" % txt
