class_name VortexHUD
extends Control

@onready var lives_container: VBoxContainer = %LivesContainer
@onready var state_label: Label = %StateLabel

func _ready() -> void:
	set_state("Waiting...")
	_clear_lives()

func update_lives(data: Array[Dictionary]) -> void:
	_clear_lives()
	for entry in data:
		var pname := str(entry.get("name", "?"))
		var lives := int(entry.get("lives", 0))
		var label := Label.new()
		label.text = "%s  %s" % [pname, "♥".repeat(lives) + "♡".repeat(maxi(0, 3 - lives))]
		label.theme_type_variation = &"LabelMedium"
		if lives <= 0:
			label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		lives_container.add_child(label)

func set_state(text: String) -> void:
	if state_label:
		state_label.text = text

func _clear_lives() -> void:
	if not lives_container:
		return
	for child in lives_container.get_children():
		child.queue_free()
