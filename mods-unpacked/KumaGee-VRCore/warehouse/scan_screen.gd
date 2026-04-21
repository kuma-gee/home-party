extends Sprite3D

@export var scanner: Scanner
@export var color: ColorRect
@export var code_label: Label
@export var types_container: Control

func _ready() -> void:
	scanner.scanned.connect(_on_scanned)
	hide()

func _on_scanned(code: String) -> void:
	var data = ScanCode.CODE_MAP.get(code, null)
	print("Scanned code: %s, Data: %s" % [code, data])

	if data:
		match data.color:
			ScanCode.ColorLabel.RED:
				color.color = Color(1, 0, 0)
			ScanCode.ColorLabel.GREEN:
				color.color = Color(0, 1, 0)
			ScanCode.ColorLabel.BLUE:
				color.color = Color(0, 0, 1)
		
		code_label.text = code
		types_container.visible = true
		
		# Clear previous type labels
		for child in types_container.get_children():
			child.queue_free()
		
		# Add new type labels
		for type in data.types:
			var type_label = Label.new()
			match type:
				ScanCode.TypeLabel.FRAGILE:
					type_label.text = "Fragile"
				ScanCode.TypeLabel.HEAVY:
					type_label.text = "Heavy"
				ScanCode.TypeLabel.PERISHABLE:
					type_label.text = "Perishable"
				ScanCode.TypeLabel.EXPLOSIVE:
					type_label.text = "Explosive"
			types_container.add_child(type_label)
	else:
		color.color = Color(1, 1, 1) # Default to white if code not found
		code_label.text = "Unknown Code"
		types_container.visible = false

	show()
