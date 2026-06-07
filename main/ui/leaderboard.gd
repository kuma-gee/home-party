class_name Leaderboard
extends Control

const VR_PLAYER_ID := "vr_player"
const WINNER_COLOR := Color(1.0, 0.84, 0.0)
const COLUMNS := 4

@onready var title_label: Label = $TitleLabel
@onready var rankings_grid: GridContainer = $ScrollContainer/RankingsGrid

var _winner_cells: Array[Label] = []

func set_title(txt: String) -> void:
	title_label.text = txt

func set_entries(entries: Array) -> void:
	for child in rankings_grid.get_children():
		child.queue_free()
	_winner_cells.clear()

	var ranked = entries.duplicate()
	ranked.sort_custom(func(a, b): return a["total_points"] > b["total_points"])

	var headers := ["#", "Player", "Score", "Rounds"]
	for header_text in headers:
		var header := Label.new()
		header.text = header_text
		header.theme_type_variation = "LabelSmall"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rankings_grid.add_child(header)

	for i in ranked.size():
		var entry = ranked[i]
		var uuid = entry.get("uuid", "")
		var player_name := "VR" if uuid == VR_PLAYER_ID else _get_player_name(uuid)

		var cells := [
			str(i + 1),
			player_name,
			str(entry["total_points"]),
			str(entry.get("rounds_guessed_correctly", 0))
		]
		for cell_text in cells:
			var cell := Label.new()
			cell.text = cell_text
			cell.theme_type_variation = "LabelSmall"
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rankings_grid.add_child(cell)

			if i == 0:
				_winner_cells.append(cell)

	if _winner_cells.size() > 0:
		_animate_winner()

func _get_player_name(uuid: String) -> String:
	var idx = PlayerManager.get_player_idx(uuid)
	if idx >= 0:
		return "P%s" % (idx + 1)
	return "P??"

func _animate_winner() -> void:
	var tw = create_tween().set_loops()
	tw.tween_method(func(v): _set_winner_color(v), 0.0, 1.0, 0.5)
	tw.tween_method(func(v): _set_winner_color(v), 1.0, 0.0, 0.5)

func _set_winner_color(weight: float) -> void:
	var color = Color.WHITE.lerp(WINNER_COLOR, weight)
	for cell in _winner_cells:
		if is_instance_valid(cell):
			cell.modulate = color
