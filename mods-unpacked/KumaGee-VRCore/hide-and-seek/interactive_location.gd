class_name InteractiveLocation
extends Area3D

## A museum interactive location (painting or plaque) that hiders can approach
## and interact with to blend into the NPC crowd.

signal player_entered(character: CharacterBody3D)
signal player_exited(character: CharacterBody3D)
signal action_performed(character: CharacterBody3D, action: Action, duration: float)

enum Action {
	LOOK,  ## Stand-and-look action (paintings, 5s)
	READ,  ## Read action (plaques, 3s)
}

@export var action: Action = Action.LOOK
@export var duration: float = 5.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func perform_action(character: CharacterBody3D) -> void:
	if not is_instance_valid(character):
		return
	action_performed.emit(character, action, duration)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		player_entered.emit(body as CharacterBody3D)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		player_exited.emit(body as CharacterBody3D)
