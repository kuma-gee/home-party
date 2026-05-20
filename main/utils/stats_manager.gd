extends Node

var stats: Dictionary = {}

func initialize(players: Array) -> void:
	stats = {}
	for client in players:
		var display = (client as ClientController).get_display_data()
		var uuid = display.get("client_id", "")
		if uuid != "":
			stats[uuid] = { "deaths": 0, "damage_dealt": 0, "name": display.get("name", ""), "icon": display.get("icon", "") }

func record_death(uuid: String) -> void:
	if stats.has(uuid):
		stats[uuid]["deaths"] += 1

func record_damage(attacker_uuid: String, amount: float) -> void:
	if stats.has(attacker_uuid):
		stats[attacker_uuid]["damage_dealt"] += amount

func get_rankings() -> Array:
	var entries: Array = []
	for uuid in stats:
		var s = stats[uuid]
		var score: float = s["damage_dealt"] - (s["deaths"] * 50)
		var player_name = s["name"].substr(0, 16)
		if s["name"].length() > 16:
			player_name += "..."
		
		entries.append({
			"uuid": uuid,
			"name": player_name,
			"icon": s["icon"],
			"deaths": s["deaths"],
			"damage_dealt": s["damage_dealt"],
			"score": score,
		})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	for i in entries.size():
		entries[i]["rank"] = i + 1
	return entries

func reset() -> void:
	stats = {}
