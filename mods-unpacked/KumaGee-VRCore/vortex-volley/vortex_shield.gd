class_name VortexShield
extends VortexWeapon

## Reflecting weapon. Any overlapping orb is deflected in the direction the palm
## faces at impact. An active swing (>= MIN_SWING_SPEED) boosts the reflect speed
## and escalates the arena; a passive block reflects at the current speed.

const SHIELD_COOLDOWN: float = 0.2

func _try_handle_orb(orb: GameOrb, active: bool) -> bool:
	var reflect_dir := _get_palm_direction()
	if reflect_dir == Vector3.ZERO:
		return false
	orb_hit.emit(orb, reflect_dir, active)
	_start_cooldown(SHIELD_COOLDOWN)
	return true
