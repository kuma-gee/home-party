class_name HideSeekHUD
extends Control

## Shared-screen HUD for Hide & Seek.
## Shows hider count, countdown timer, player list (alive/eliminated),
## found feed, and the Seeker's tag cooldown.

var hider_count: int = 0:
	set(v):
		hider_count = v
		_update_hider_count()

var time_remaining: float = 90.0:
	set(v):
		time_remaining = v
		_update_timer()

var found_feed: Array[String] = []:
	set(v):
		found_feed = v
		_update_found_feed()

var player_statuses: Array[Dictionary] = []:
	set(v):
		player_statuses = v
		_update_player_list()

var tag_cooldown: float = 0.0:
	set(v):
		tag_cooldown = v
		_update_tag_cooldown()

var preparing: bool = false:
	set(v):
		preparing = v
		_update_preparing()

@onready var hider_count_label: Label = %HiderCountLabel
@onready var timer_label: Label = %TimerLabel
@onready var found_feed_container: VBoxContainer = %FoundFeedContainer
@onready var player_list_container: VBoxContainer = %PlayerListContainer
@onready var tag_cooldown_label: Label = %TagCooldownLabel
@onready var prepare_overlay: Control = %PrepareOverlay


func _ready() -> void:
	_update_hider_count()
	_update_timer()
	_update_found_feed()
	_update_player_list()
	_update_tag_cooldown()
	_update_preparing()


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
	for child in found_feed_container.get_children():
		child.queue_free()
	var count: int = mini(found_feed.size(), 5)
	for i in count:
		var label := Label.new()
		label.text = found_feed[i]
		label.theme_type_variation = "LabelMedium"
		found_feed_container.add_child(label)


func _update_player_list() -> void:
	if not player_list_container:
		return
	for child in player_list_container.get_children():
		child.queue_free()
	for entry in player_statuses:
		var label := Label.new()
		var name: String = str(entry.get("name", "Unknown"))
		var alive: bool = bool(entry.get("alive", false))
		if alive:
			label.text = "● %s" % name
			label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		else:
			label.text = "✗ %s" % name
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		label.theme_type_variation = "LabelMedium"
		player_list_container.add_child(label)


func _update_tag_cooldown() -> void:
	if not tag_cooldown_label:
		return
	if tag_cooldown > 0.0:
		tag_cooldown_label.text = "Tag: %.0fs" % ceil(tag_cooldown)
		tag_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	else:
		tag_cooldown_label.text = "Tag: ready"
		tag_cooldown_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))


func _update_preparing() -> void:
	if prepare_overlay:
		prepare_overlay.visible = preparing
