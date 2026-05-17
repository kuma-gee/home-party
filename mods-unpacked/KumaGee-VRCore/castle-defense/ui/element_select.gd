class_name ElementSelect
extends PanelContainer

signal ready_pressed(element: Arrow.Element)

var selected_element: Arrow.Element = Arrow.Element.FIRE

@export var fire_button: Button
@export var ice_button: Button
@export var selected_label: Label
@export var ready_button: Button

func _ready() -> void:
	fire_button.pressed.connect(func(): _select_element(Arrow.Element.FIRE))
	ice_button.pressed.connect(func(): _select_element(Arrow.Element.ICE))
	ready_button.pressed.connect(func(): ready_pressed.emit(selected_element))
	
	_update_element_visuals()
	ready_button.disabled = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key = event as InputEventKey
		if key.shift_pressed and key.keycode == KEY_1:
			ready_pressed.emit(Arrow.Element.FIRE)

func update_ready(ready_count: int, player_count: int):
	if ready_count == player_count:
		ready_button.text = "Start game"
	else:
		ready_button.text = "mobile ready %s / %s" % [ready_count, player_count]
	ready_button.disabled = ready_count != player_count

func _select_element(element: Arrow.Element) -> void:
	selected_element = element
	_update_element_visuals()

func _update_element_visuals() -> void:
	fire_button.button_pressed = selected_element == Arrow.Element.FIRE
	ice_button.button_pressed = selected_element == Arrow.Element.ICE
	match selected_element:
		Arrow.Element.FIRE:
			selected_label.text = "Selected: 🔥 Fire"
		Arrow.Element.ICE:
			selected_label.text = "Selected: ❄️ Ice"
