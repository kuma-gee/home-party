@tool
class_name LabeledStepSlider
extends VBoxContainer

signal value_changed(value: int)

const ACTIVE_VARIATION := &"LabelSliderActive"
const INACTIVE_VARIATION := &"LabelSliderInactive"

@export var option_texts: PackedStringArray = PackedStringArray(): set = set_option_texts
@export var value: int = 0: set = set_value

@onready var _slider: HSlider = %Slider
@onready var _labels: HBoxContainer = %Labels

var _is_ready := false


func _ready() -> void:
	_is_ready = true
	_slider.value_changed.connect(_on_slider_value_changed)
	_rebuild_labels()
	_sync_slider_range()
	_sync_slider_value()
	_update_active_label()


func set_option_texts(new_option_texts: PackedStringArray) -> void:
	option_texts = new_option_texts
	if _is_ready:
		_rebuild_labels()
		_sync_slider_range()
		_sync_slider_value()
		_update_active_label()


func set_value(new_value: int) -> void:
	value = clampi(new_value, 0, maxi(option_texts.size() - 1, 0))
	if _is_ready:
		_sync_slider_value()
		_update_active_label()


func _rebuild_labels() -> void:
	for child in _labels.get_children():
		_labels.remove_child(child)
		child.queue_free()

	for option_text in option_texts:
		var label := Label.new()
		label.text = option_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_type_variation = INACTIVE_VARIATION
		_labels.add_child(label)


func _sync_slider_range() -> void:
	_slider.min_value = 0.0
	_slider.max_value = maxi(option_texts.size() - 1, 0)
	_slider.step = 1.0
	_slider.tick_count = option_texts.size()


func _sync_slider_value() -> void:
	_slider.value = value


func _update_active_label() -> void:
	var active_index := roundi(_slider.value)
	for index in _labels.get_child_count():
		var label := _labels.get_child(index) as Label
		if label:
			label.theme_type_variation = ACTIVE_VARIATION if index == active_index else INACTIVE_VARIATION


func _on_slider_value_changed(new_value: float) -> void:
	value = roundi(new_value)
	_update_active_label()
	value_changed.emit(value)
