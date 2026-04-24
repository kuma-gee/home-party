class_name GameResource
extends Resource

@export var name: String
@export var description: String
@export var scene: PackedScene
@export var icon: PackedScene
@export var min_recommended_players := 2
@export var max_recommended_players := -1
@export var tags: Array[TagResource] = []
