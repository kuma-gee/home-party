extends Node

const APP_ID = 4797040

const CASTLE_DEFENSE = preload("uid://bisblrq6vyivi")
const DRAW_AND_GUESS = preload("uid://dagresource")
const demo_games: Array[GameResource] = [CASTLE_DEFENSE, DRAW_AND_GUESS]

var log_level := KumaLog.Level.DEBUG
var version := Build.VERSION
var _logger := KumaLog.new("Env")

var _live := false
var _enable_steam := true
var _default_log_level := KumaLog.Level.INFO
var _has_played_game := false

func _ready():
	var args = _args_dictionary()
	_logger.info("Args: %s" % args)

	_reset_values()
	_parse_logging_arg(args)
	_parse_live_arg(args)
	_parse_steam_arg(args)
	
	if _enable_steam and Build.STEAM_APP != APP_ID and not is_editor():
		_live = false
		_logger.warn("This build isn't designed to be used live")
	
	_logger.info("Running version %s (%s) on %s: %s" % [version, Build.GIT_SHA, OS.get_name(), {
		"demo": is_demo(),
		"steam": is_steam(),
		"log_level": KumaLog.Level.keys()[log_level],
	}])


func _reset_values():
	if not is_editor():
		_live = false
		_enable_steam = false
		log_level = _default_log_level


func _parse_logging_arg(args):
	if "logging" in args:
		var lvl_str = args["logging"].to_upper()
		log_level = KumaLog.Level[lvl_str] if lvl_str in KumaLog.Level else _default_log_level
		_logger.info("Setting log level to %s" % KumaLog.Level.keys()[log_level])


func _parse_live_arg(args):
	if "live" in args:
		var used_hash = args["live"].sha256_text()
		_logger.debug("Checking hash %s is equal %s" % [used_hash, Build.GAME_HASH])
		_live = used_hash == Build.GAME_HASH or is_editor()


func _parse_steam_arg(args):
	if "steam" in args:
		_enable_steam = true


func is_editor():
	return OS.is_debug_build()

func is_web() -> bool:
	return OS.has_feature("web")

func is_demo() -> bool:
	return not _live


func mark_game_played() -> void:
	_has_played_game = true


func has_played_game() -> bool:
	return _has_played_game


func is_game_available(game: GameResource) -> bool:
	if not game:
		return false
	if not is_demo():
		return true
	for demo_game in demo_games:
		if demo_game == game:
			return true
		if demo_game and demo_game.resource_path == game.resource_path:
			return true
	return false

func is_steam() -> bool:
	return _enable_steam

func is_debug_level():
	return log_level == KumaLog.Level.DEBUG

func _args_dictionary():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			arguments[argument.lstrip("--")] = ""

	return arguments

func _get_hash(s: String):
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(s.to_utf8_buffer())
	var res = ctx.finish()
	return res.hex_encode()
