class_name ElementSelect
extends PanelContainer

signal ready_pressed(elements: Array[Arrow.Element])

const ELEMENT_DATA := [
	[Arrow.Element.FIRE, "🔥 Fire"],
	[Arrow.Element.ICE, "❄️ Ice"],
	[Arrow.Element.LIGHTNING, "⚡ Lightning"],
	[Arrow.Element.WIND, "🌪️ Wind"],
	[Arrow.Element.POISON, "☠️ Poison"],
	#[Arrow.Element.VOID, "🌑 Void"],
]

const ELEMENT_EMOJIS := {
	Arrow.Element.FIRE: "🔥",
	Arrow.Element.ICE: "❄️",
	Arrow.Element.LIGHTNING: "⚡",
	Arrow.Element.WIND: "🌪️",
	Arrow.Element.POISON: "☠️",
	#Arrow.Element.VOID: "🌑",
}

const ELEMENT_TEXT := {
	Arrow.Element.FIRE: "Explodes and hit enemies in a small area",
	Arrow.Element.ICE: "Freezes in impact and slows enemies in an area",
	Arrow.Element.LIGHTNING: "Hits the closest enemy and bounces up to 3 times",
	Arrow.Element.WIND: "Creating a tornado pulling enemies towards it",
	Arrow.Element.POISON: "Poisons enemies in a large area",
}

var selected_elements: Array[Arrow.Element] = [Arrow.Element.FIRE, Arrow.Element.ICE, Arrow.Element.LIGHTNING]
var _mobile_ready := false

@export var element_buttons_container: Control
@export var ready_button: Button
@export var max_elements := 3

@onready var title_label: Label = %Title

static func get_element_icon(element: Arrow.Element) -> String:
	for entry in ELEMENT_EMOJIS.keys():
		if entry == element:
			return ELEMENT_EMOJIS[entry]
	return "Unknown"

const ELEMENT_BUTTON_SCENE := preload("res://mods-unpacked/KumaGee-VRCore/castle-defense/ui/element_button.tscn")


func _ready() -> void:
	for entry in ELEMENT_DATA:
		var element: Arrow.Element = entry[0]
		var label: String = entry[1]
		var btn: ElementButton = ELEMENT_BUTTON_SCENE.instantiate()
		var name_only := label.substr(label.find(" ") + 1)
		btn.set_element(element, ELEMENT_EMOJIS[element], name_only, ELEMENT_TEXT[element])
		btn.set_selected(element in selected_elements)
		btn.pressed.connect(func(): _toggle_element(element, btn))
		element_buttons_container.add_child(btn)

	ready_button.pressed.connect(func(): ready_pressed.emit(selected_elements))
	ready_button.disabled = true
	_update()

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

func _toggle_element(element: Arrow.Element, btn: ElementButton) -> void:
	if element in selected_elements:
		selected_elements.erase(element)
		btn.set_selected(false)
	elif selected_elements.size() < max_elements:
		selected_elements.append(element)
		btn.set_selected(true)
	else:
		btn.set_selected(false)
	
	_update()

func _update():
	title_label.text = "Select Elements (%d/%d)" % [selected_elements.size(), max_elements]
	_set_disabled_for_unpressed(selected_elements.size() >= max_elements)
	ready_button.disabled = not _mobile_ready or selected_elements.is_empty()
	
func _set_disabled_for_unpressed(disable = false):
	for child in element_buttons_container.get_children():
		if child is ElementButton and not child.is_selected():
			child.set_disabled(disable)
