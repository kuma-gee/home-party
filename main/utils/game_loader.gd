class_name GameLoader
extends Node

const MOD_FOLDER = "res://mods-unpacked/"

func list_games() -> Array[GameResource]:
	var result: Array[GameResource] = []
	var mods = ModLoaderUserProfile.get_current().mod_list.keys()

	for mod in mods:
		var path = MOD_FOLDER + mod + "/"
		_load_games(path, result)

	return result

func _load_games(path: String, result: Array[GameResource]):
	for file in ResourceLoader.list_directory(path):
		var current = path + file
		if DirAccess.dir_exists_absolute(current):
			_load_games(current, result)
			continue
			
		var res = ResourceLoader.load(current)
		if res is GameResource:
			result.append(res)
