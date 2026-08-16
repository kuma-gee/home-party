class_name Leaderboard
extends Control

const WINNER_COLOR := Color(1.0, 0.84, 0.0)

@onready var title_label: Label = $TitleLabel
@onready var rankings_grid: GridContainer = $ScrollContainer/RankingsGrid

var _winner_cells: Array[Label] = []
var _winner_tween: Tween

func set_title(txt: String) -> void:
	title_label.text = txt

func set_table(headers: Array[String], rows: Array, highlight_first_row := false) -> void:
	_clear_grid()
	rankings_grid.columns = max(headers.size(), 1)

	for header_text in headers:
		_add_cell(header_text, true)

	for row_idx in rows.size():
		var row: Array = rows[row_idx]
		for value in row:
			var cell := _add_cell(str(value))
			if highlight_first_row and row_idx == 0:
				_winner_cells.append(cell)

	if _winner_cells.size() > 0:
		_animate_winner()

func set_entries(entries: Array) -> void:
	var ranked = entries.duplicate()
	ranked.sort_custom(func(a, b): return int(a.get("total_points", a.get("score", 0))) > int(b.get("total_points", b.get("score", 0))))

	var has_rounds := false
	for entry in ranked:
		if entry.has("rounds_guessed_correctly"):
			has_rounds = true
			break

	var headers: Array[String] = ["#", "Player", "Score"]
	if has_rounds:
		headers.append("Rounds")

	var rows: Array = []

	for i in ranked.size():
		var entry = ranked[i]
		var cells: Array = [
			str(i + 1),
			_get_display_name(entry),
			str(entry.get("total_points", entry.get("score", 0)))
		]
		if has_rounds:
			cells.append(str(entry.get("rounds_guessed_correctly", 0)))
		rows.append(cells)

	set_table(headers, rows, true)

func set_rankings(rankings: Array) -> void:
	var headers: Array[String] = ["#", "P#", "Firepower", "Damage", "Score"]
	var rows: Array = []

	for entry in rankings:
		rows.append([
			str(entry.get("rank", "")),
			str(entry.get("name", "")),
			str(entry.get("firepower", 0)),
			str(entry.get("damage_dealt", 0)),
			str(entry.get("score", 0)),
		])

	set_table(headers, rows)

func _get_player_name(uuid: String) -> String:
	var idx = PlayerManager.get_player_idx(uuid)
	if idx >= 0:
		return "P%s" % (idx + 1)
	return "P??"

func _get_display_name(entry: Dictionary) -> String:
	if entry.has("name"):
		return str(entry.get("name", "P??"))

	var uuid := str(entry.get("uuid", ""))
	if not uuid.is_empty():
		return _get_player_name(uuid)
	return "P??"

func _clear_grid() -> void:
	for child in rankings_grid.get_children():
		child.queue_free()
	_winner_cells.clear()
	if is_instance_valid(_winner_tween):
		_winner_tween.kill()
		_winner_tween = null

func _add_cell(text: String, is_header := false) -> Label:
	var cell := Label.new()
	cell.text = text
	cell.theme_type_variation = "LabelSmall"
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_header:
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rankings_grid.add_child(cell)
	return cell

func _animate_winner() -> void:
	_winner_tween = create_tween().set_loops()
	_winner_tween.tween_method(func(v): _set_winner_color(v), 0.0, 1.0, 0.5)
	_winner_tween.tween_method(func(v): _set_winner_color(v), 1.0, 0.0, 0.5)

func _set_winner_color(weight: float) -> void:
	var color = Color.WHITE.lerp(WINNER_COLOR, weight)
	for cell in _winner_cells:
		if is_instance_valid(cell):
			cell.modulate = color
