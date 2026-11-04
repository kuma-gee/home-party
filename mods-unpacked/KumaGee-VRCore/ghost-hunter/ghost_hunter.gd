class_name GhostHunter
extends BaseGame

@export var house_variants: Array[PackedScene] = []
@export var house_container: Node3D

var logger := KumaLog.new("GHOST_HUNTER")
var house: HouseLayout = null


func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)
	_load_random_house()


func _load_random_house() -> void:
	if house_variants.is_empty() or not house_container:
		logger.warn("No haunted house variants configured")
		return
	
	var variant: PackedScene = house_variants[randi() % house_variants.size()]
	house = variant.instantiate() as HouseLayout
	house_container.add_child(house)
	logger.info("Loaded haunted house layout: %s" % house.name)


func _on_prepare_phase() -> void:
	pass


func _on_game_phase() -> void:
	pass
