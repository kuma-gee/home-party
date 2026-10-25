class_name VortexWeaponSelect
extends PanelContainer

## VR prepare-page weapon picker. Each hand independently chooses a shield or a
## saber. Emits the current pair so the game can equip the hands before start.

signal weapons_changed(left: VortexWeapon.Weapon, right: VortexWeapon.Weapon)

@export var left_shield_button: TextureButton
@export var left_saber_button: TextureButton
@export var right_shield_button: TextureButton
@export var right_saber_button: TextureButton

var selected_left: VortexWeapon.Weapon = VortexWeapon.Weapon.SHIELD
var selected_right: VortexWeapon.Weapon = VortexWeapon.Weapon.SABER

func _ready() -> void:
	_setup_button(left_shield_button, true, VortexWeapon.Weapon.SHIELD)
	_setup_button(left_saber_button, true, VortexWeapon.Weapon.SABER)
	_setup_button(right_shield_button, false, VortexWeapon.Weapon.SHIELD)
	_setup_button(right_saber_button, false, VortexWeapon.Weapon.SABER)
	_update_buttons()

func _setup_button(button: TextureButton, is_left: bool, weapon: VortexWeapon.Weapon) -> void:
	if not is_instance_valid(button):
		return
	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.toggle_mode = true
	button.pressed.connect(_on_weapon_pressed.bind(is_left, weapon))

func _on_weapon_pressed(is_left: bool, weapon: VortexWeapon.Weapon) -> void:
	if is_left:
		selected_left = weapon
	else:
		selected_right = weapon
	_update_buttons()
	weapons_changed.emit(selected_left, selected_right)

func _update_buttons() -> void:
	_set_button_selected(left_shield_button, selected_left == VortexWeapon.Weapon.SHIELD)
	_set_button_selected(left_saber_button, selected_left == VortexWeapon.Weapon.SABER)
	_set_button_selected(right_shield_button, selected_right == VortexWeapon.Weapon.SHIELD)
	_set_button_selected(right_saber_button, selected_right == VortexWeapon.Weapon.SABER)

func _set_button_selected(button: TextureButton, selected: bool) -> void:
	if not is_instance_valid(button):
		return
	button.set_pressed_no_signal(selected)
	button.modulate = Color.WHITE if selected else Color(1, 1, 1, 0.4)
