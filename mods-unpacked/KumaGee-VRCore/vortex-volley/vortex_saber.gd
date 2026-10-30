class_name VortexSaber
extends VortexWeapon

## Slicing weapon. Any contact cuts the orb — no minimum swing speed required.

const SABER_COOLDOWN: float = 0.3

func _try_handle_orb(orb: GameOrb, _active: bool) -> bool:
	var slice_dir := _get_palm_direction()
	if slice_dir == Vector3.ZERO:
		return false
	orb_sliced.emit(orb, slice_dir)
	_start_cooldown(SABER_COOLDOWN)
	return true
