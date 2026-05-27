class_name CastleDefenseTutorial
extends Node3D

@export var bow: Bow
@export var quiver: Quiver

@onready var _camera_follow: CameraFollow3D = $CameraFollow3D
@onready var _grab_label: Label3D = $CameraFollow3D/Label3D
@onready var _orb_label: Label3D = $CameraFollow3D/Label3D2

var _has_grabbed_bow := false
var _has_grabbed_arrow := false

func _ready() -> void:
	_camera_follow.hide()
	bow.picked_up.connect(_on_bow_picked_up)
	quiver.picked_up.connect(_on_arrow_grabbed)
	quiver.element_changed.connect(_on_element_changed)

func finish() -> void:
	_camera_follow.hide()

func _on_bow_picked_up(_pickable: XRToolsPickable) -> void:
	if _has_grabbed_bow:
		return
	_has_grabbed_bow = true
	_camera_follow.show()

func _on_arrow_grabbed(_what: Node3D) -> void:
	if _has_grabbed_arrow or not _has_grabbed_bow:
		return
	_has_grabbed_arrow = true
	_grab_label.hide()
	_orb_label.show()

func _on_element_changed(elem: Arrow.Element) -> void:
	if _has_grabbed_arrow and elem != Arrow.Element.NONE:
		_camera_follow.hide()
