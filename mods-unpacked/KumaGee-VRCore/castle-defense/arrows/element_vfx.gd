class_name ElementVFX
extends Node3D

const VFX_SCENES = {
	Arrow.Element.FIRE:      "res://mods-unpacked/KumaGee-VRCore/castle-defense/arrows/vfx/orb_fire_vfx.tscn",
	Arrow.Element.ICE:       "res://mods-unpacked/KumaGee-VRCore/castle-defense/arrows/vfx/orb_ice_vfx.tscn",
	Arrow.Element.LIGHTNING: "res://mods-unpacked/KumaGee-VRCore/castle-defense/arrows/vfx/orb_lightning_vfx.tscn",
	Arrow.Element.WIND:      "res://mods-unpacked/KumaGee-VRCore/castle-defense/arrows/vfx/orb_wind_vfx.tscn",
	Arrow.Element.POISON:    "res://mods-unpacked/KumaGee-VRCore/castle-defense/arrows/vfx/orb_poison_vfx.tscn",
	Arrow.Element.VOID:      "res://mods-unpacked/KumaGee-VRCore/castle-defense/arrows/vfx/orb_void_vfx.tscn",
}

@export var element := Arrow.Element.NONE:
	set(v):
		element = v
		if is_node_ready():
			_swap_vfx(element)

var _vfx_instance: Node3D = null

func _ready() -> void:
	_swap_vfx(element)

func _swap_vfx(elem: Arrow.Element) -> void:
	if _vfx_instance:
		_vfx_instance.queue_free()
		_vfx_instance = null
	if elem in VFX_SCENES:
		_vfx_instance = load(VFX_SCENES[elem]).instantiate()
		add_child(_vfx_instance)
