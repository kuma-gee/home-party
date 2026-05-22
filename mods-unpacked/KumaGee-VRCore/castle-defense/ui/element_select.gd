class_name ElementSelect
extends PanelContainer

signal ready_pressed(elements: Array[Arrow.Element])

const ELEMENT_DATA := [
	[Arrow.Element.FIRE, "🔥 Fire"],
	[Arrow.Element.ICE, "❄️ Ice"],
	[Arrow.Element.LIGHTNING, "⚡ Lightning"],
	[Arrow.Element.WIND, "🌪️ Wind"],
	[Arrow.Element.POISON, "☠️ Poison"],
	[Arrow.Element.VOID, "🌑 Void"],
]

const ELEMENT_EMOJIS := {
	Arrow.Element.FIRE: "🔥",
	Arrow.Element.ICE: "❄️",
	Arrow.Element.LIGHTNING: "⚡",
	Arrow.Element.WIND: "🌪️",
	Arrow.Element.POISON: "☠️",
	Arrow.Element.VOID: "🌑",
}

var selected_elements: Array[Arrow.Element] = [Arrow.Element.FIRE, Arrow.Element.ICE, Arrow.Element.LIGHTNING]
var _mobile_ready := false

@export var element_buttons_container: Control
@export var selected_label: Label
@export var ready_button: Button
@export var max_elements := 3

static func get_element_icon(element: Arrow.Element) -> String:
	for entry in ELEMENT_EMOJIS.keys():
		if entry == element:
			return ELEMENT_EMOJIS[entry]
	return "Unknown"

func _ready() -> void:
	for entry in ELEMENT_DATA:
		var element: Arrow.Element = entry[0]
		var label: String = entry[1]
		var btn := Button.new()
		btn.text = label
		btn.toggle_mode = true
		btn.button_pressed = element in selected_elements
		btn.pressed.connect(func(): _toggle_element(element, btn))
		element_buttons_container.add_child(btn)

	ready_button.pressed.connect(func(): ready_pressed.emit(selected_elements))
	ready_button.disabled = true
	_update_selected_label()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_1"):
		ready_pressed.emit(selected_elements)

func update_ready(ready_count: int, player_count: int) -> void:
	_mobile_ready = ready_count == player_count
	if _mobile_ready:
		ready_button.text = "Start game"
	else:
		ready_button.text = "mobile ready %s / %s" % [ready_count, player_count]
	ready_button.disabled = not _mobile_ready or selected_elements.is_empty()

func _toggle_element(element: Arrow.Element, btn: Button) -> void:
	if element in selected_elements:
		selected_elements.erase(element)
		btn.button_pressed = false
	elif selected_elements.size() < max_elements:
		selected_elements.append(element)
		btn.button_pressed = true
	else:
		btn.button_pressed = false
	
	_update()

func _update():
	_set_disabled_for_unpressed(selected_elements.size() >= max_elements)
	_update_selected_label()
	ready_button.disabled = not _mobile_ready or selected_elements.is_empty()
	
func _set_disabled_for_unpressed(disable = false):
	for child in element_buttons_container.get_children():
		if child is Button and not child.button_pressed:
			child.disabled = disable

func _update_selected_label() -> void:
	var emojis := " ".join(selected_elements.map(func(e): return get_element_icon(e)))
	selected_label.text = "Selected: %s" % emojis
