class_name VortexSaber
extends VortexWeapon

## Slicing weapon. A swing at or above MIN_SWING_SPEED splits an overlapping orb
## into two. A held-still saber does not slice.

const SABER_COOLDOWN: float = 0.3

func _try_handle_orb(orb: GameOrb, active: bool) -> bool:
	if not active:
		return false
	var slice_dir := _get_palm_direction()
	if slice_dir == Vector3.ZERO:
		return false
	orb_sliced.emit(orb, slice_dir)
	_start_cooldown(SABER_COOLDOWN)
	return true
