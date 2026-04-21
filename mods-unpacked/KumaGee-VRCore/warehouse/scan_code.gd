class_name ScanCode
extends Area3D

enum ColorLabel {
	RED,
	GREEN,
	BLUE,
}

enum TypeLabel {
	FRAGILE,
	HEAVY,
	PERISHABLE,
	EXPLOSIVE,
}

const CODE_MAP = {
	"G521": {"color": ColorLabel.GREEN, "types": []},
	"R123H23T": {"color": ColorLabel.RED, "types": [TypeLabel.HEAVY]},
	"R998": {"color": ColorLabel.RED, "types": [TypeLabel.FRAGILE]},
	"B200X": {"color": ColorLabel.BLUE, "types": [TypeLabel.PERISHABLE]},
	"G440F": {"color": ColorLabel.GREEN, "types": [TypeLabel.HEAVY, TypeLabel.FRAGILE]},
	"R321P": {"color": ColorLabel.RED, "types": [TypeLabel.EXPLOSIVE]},
	"B77": {"color": ColorLabel.BLUE, "types": []},
	"G007": {"color": ColorLabel.GREEN, "types": [TypeLabel.PERISHABLE, TypeLabel.FRAGILE]},
	"R500H": {"color": ColorLabel.RED, "types": [TypeLabel.HEAVY, TypeLabel.PERISHABLE]},
	"B3EXP": {"color": ColorLabel.BLUE, "types": [TypeLabel.EXPLOSIVE, TypeLabel.HEAVY]},
	"G888": {"color": ColorLabel.GREEN, "types": [TypeLabel.FRAGILE]},
	"R200T": {"color": ColorLabel.RED, "types": [TypeLabel.HEAVY, TypeLabel.EXPLOSIVE]},
}

@export var barcode: BarCode39

func _ready():
	barcode.barcode_text = CODE_MAP.keys()[randi() % CODE_MAP.size()]

func get_code():
	return barcode.barcode_text
