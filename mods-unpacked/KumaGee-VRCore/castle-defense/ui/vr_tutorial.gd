class_name VRTutorial
extends Control

## Emitted whenever the visible page changes. Pages are 1-indexed.
signal page_changed(page: int)
## Emitted when the optional [member ready_button] is pressed.
signal ready_pressed

## Ready button controlled by the tutorial. When left empty it falls back to
## the nested [ElementSelect] button, if one exists.
@export var ready_button: Button
## Label used for the ready button once the player can proceed.
@export var ready_text := "Ready"
## Format used while waiting for players: ready count, then player count.
@export var waiting_text := "Ready (%s/%s)"

@onready var _pages: Control = %Pages
@onready var _back_button: Button = %BackButton
@onready var _page_label: Label = %PageLabel
@onready var _next_button: Button = %NextButton
## Optional page content - not every game uses element selection.
@onready var element_select: ElementSelect = get_node_or_null("%ElementSelect") as ElementSelect

var _current_page: int = 1

func _ready() -> void:
	if not is_instance_valid(ready_button) and is_instance_valid(element_select):
		ready_button = element_select.ready_button
	if is_instance_valid(ready_button):
		ready_button.text = ready_text
		ready_button.pressed.connect(_on_ready_pressed)
	show_page(1)

## Updates the ready button text and forwards the readiness state to the
## optional [ElementSelect].
func update_ready(ready_count: int, player_count: int) -> void:
	if is_instance_valid(element_select): # legacy stuff
		element_select.update_ready(ready_count, player_count)
	if is_instance_valid(ready_button):
		ready_button.text = ready_text if ready_count == player_count else waiting_text % [ready_count, player_count]

func get_page_count() -> int:
	return _pages.get_child_count()

func get_current_page() -> int:
	return _current_page

## Shows [param page], clamped to the pages available under %Pages.
func show_page(page: int) -> void:
	var page_count := get_page_count()
	if page_count == 0:
		return

	_current_page = clampi(page, 1, page_count)
	for index in page_count:
		_pages.get_child(index).visible = index == _current_page - 1

	_back_button.visible = _current_page > 1
	_next_button.visible = _current_page < page_count
	_page_label.text = "%d / %d" % [_current_page, page_count]
	page_changed.emit(_current_page)

func next_page() -> void:
	show_page(_current_page + 1)

func previous_page() -> void:
	show_page(_current_page - 1)

func _on_back_pressed() -> void:
	previous_page()

func _on_next_pressed() -> void:
	next_page()

func _on_ready_pressed() -> void:
	ready_pressed.emit()
