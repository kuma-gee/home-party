class_name HideSeekHUD
extends Control

## Shared screen HUD for Hide & Seek
## Shows hider count badge, countdown timer, and found feed.

@onready var hider_count_label: Label = %HiderCountLabel
@onready var timer_label: Label = %TimerLabel
@onready var found_feed_container: VBoxContainer = %FoundFeedContainer

var hider_count: int = 0:
	set(v):
		hider_count = v
		_update_hider_count()

var time_remaining: float = 120.0:
	set(v):
		time_remaining = v
		_update_timer()

var found_feed: Array[String] = []:
	set(v):
		found_feed = v
		_update_found_feed()

func _ready() -> void:
	_update_hider_count()
	_update_timer()

func _update_hider_count() -> void:
	if hider_count_label:
		hider_count_label.text = "%d hiding" % hider_count

func _update_timer() -> void:
	if timer_label:
		var minutes: int = int(time_remaining) / 60
		var seconds: int = int(time_remaining) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]

func _update_found_feed() -> void:
	if not found_feed_container:
		return
	
	# Clear existing entries
	for child in found_feed_container.get_children():
		child.queue_free()
	
	# Add new entries (most recent first, show up to 5)
	var count = mini(found_feed.size(), 5)
	for i in count:
		var label = Label.new()
		label.text = found_feed[i]
		label.theme_type_variation = "LabelMedium"
		found_feed_container.add_child(label)
