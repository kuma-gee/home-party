extends Node

const KUMAGEE_CORE_DIR := "KumaGee-Core"
const KUMAGEE_CORE_LOG_NAME := "KumaGee-Core:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(KUMAGEE_CORE_DIR)
	install_script_extensions()
	add_translations()

func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")
	# ModLoaderMod.install_script_extension(extensions_dir_path.path_join(...))

func add_translations() -> void:
	translations_dir_path = mod_dir_path.path_join("translations")
	# ModLoaderMod.add_translation(translations_dir_path.path_join(...))

func _ready() -> void:
	ModLoaderLog.info("Ready!", KUMAGEE_CORE_LOG_NAME)
