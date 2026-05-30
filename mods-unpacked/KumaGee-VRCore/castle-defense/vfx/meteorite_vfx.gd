extends CharacterBody3D

@export var damage: int = 10
@export var gravity: float = 20.0

var _impact_triggered: bool = false

func _physics_process(delta: float) -> void:
	if _impact_triggered:
		return
	
	velocity.y -= gravity * delta
	if velocity.length() > 0.1:
		$Meteorite.look_at(global_position + velocity, Vector3.UP)
	
	if move_and_slide():
		trigger_impact()

func trigger_impact() -> void:
	if _impact_triggered:
		return
	
	_impact_triggered = true
	velocity = Vector3.ZERO
	
	if has_node("ImpactVFX"):
		$ImpactVFX.position.y = 0
	
	if has_node("AnimationPlayer"):
		var anim_player = $AnimationPlayer
		if anim_player.has_animation("start"):
			anim_player.play("start")
	
