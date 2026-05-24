@tool
class_name MaterialIcon
extends RichTextLabel

@export var code := "f370":
	set(v):
		code = v
		update()

func _ready() -> void:
	update()
	
func update():
	text = "[center]%s[/center]" % code
