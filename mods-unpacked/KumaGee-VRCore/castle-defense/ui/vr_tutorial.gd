class_name VRTutorial
extends PanelContainer

@onready var _page_1: Control = %Page1_Tutorial
@onready var _page_2: Control = %Page2_Prepare
@onready var _back_button: Button = %BackButton
@onready var _page_label: Label = %PageLabel
@onready var _next_button: Button = %NextButton
@onready var element_select: ElementSelect = %ElementSelect

var _current_page: int = 1

func _ready() -> void:
	_show_page(1)

func _show_page(page: int) -> void:
	_current_page = page
	_page_1.visible = page == 1
	_page_2.visible = page == 2

	_back_button.visible = page > 1
	_next_button.visible = page < 2
	_page_label.text = "%d / 2" % page

func _on_back_pressed() -> void:
	if _current_page > 1:
		_show_page(_current_page - 1)

func _on_next_pressed() -> void:
	if _current_page < 2:
		_show_page(_current_page + 1)
