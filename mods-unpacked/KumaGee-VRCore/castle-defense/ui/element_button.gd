class_name ElementButton
extends Control

signal pressed

@export var element: Arrow.Element

@export var _emoji_label: Label
@export var _name_label: Label
@export var _description_label: Label
@export var _button: Button


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	pressed.emit()


func set_element(elem: Arrow.Element, emoji: String, name: String, description: String) -> void:
	self.element = elem
	_emoji_label.text = emoji
	_button.text = "             %s\n             %s" % [name, description]
	_name_label.text = name
	_description_label.text = description


func set_selected(selected: bool) -> void:
	_button.button_pressed = selected


func set_disabled(disabled: bool) -> void:
	_button.disabled = disabled


func is_selected() -> bool:
	return _button.button_pressed
