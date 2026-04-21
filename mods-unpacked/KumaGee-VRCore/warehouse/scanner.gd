@tool
class_name Scanner
extends XRToolsPickable

signal scanned(code: String)

@export var ray_cast: RayCast3D

func _ready() -> void:
	super()
	action_pressed.connect(_scan_target)

func _scan_target(_p) -> void:
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider is ScanCode:
			var scan_code = collider as ScanCode
			scanned.emit(scan_code.barcode.barcode_text)
