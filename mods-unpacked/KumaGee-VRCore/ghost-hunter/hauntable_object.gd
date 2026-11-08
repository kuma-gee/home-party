class_name HauntableObject
extends Node3D

## GH-8 hauntable prop (doll with a small lamp) placed at the house's
## gh_haunt_spot markers (spawned by HouseLayout). A ghost pressing A near it
## possesses it: the ghost hides inside (GhostPlayer clears its meshes and
## render layers) and the prop twitches while emitting a subtle audio loop.
## Pressing A again triggers the prop's effect — light flicker, door creak, or
## a twitch burst. The Flash Device purge (GH-6) forces the ghost out through
## GhostPlayer.purge_haunt, which calls [method release].

signal possessed(ghost: GhostPlayer)
signal released(ghost: GhostPlayer)
signal effect_triggered(ghost: GhostPlayer)

enum EffectType { FLICKER, CREAK, TWITCH }

const GROUP_HAUNTABLE := "gh_hauntable"
const TWITCH_INTERVAL := 0.35
const FLICKER_DURATION := 1.2
const FLICKER_ENERGY := 3.0
const HAUNT_VOLUME_DB := -20.0

const DEFAULT_HAUNT_SOUND := preload("res://assets/sound/sfx/風が吹く4.mp3")
const DEFAULT_EFFECT_SOUNDS := {
	EffectType.FLICKER: preload("res://assets/sound/sfx/雷魔法4.wav"),
	EffectType.CREAK: preload("res://assets/sound/sfx/拍子木1.mp3"),
	EffectType.TWITCH: preload("res://assets/sound/sfx/rattling-bones.mp3"),
}

@export var effect_type: EffectType = EffectType.TWITCH
@export var haunt_sound: AudioStream
@export var effect_sound: AudioStream

@onready var _prop: Node3D = %Prop
@onready var _lamp: OmniLight3D = %Lamp
@onready var _haunt_audio: AudioStreamPlayer3D = %HauntAudio
@onready var _effect_audio: AudioStreamPlayer3D = %EffectAudio

var possessor: GhostPlayer = null

var _twitch_timer := 0.0
var _flicker_timer := 0.0


func _ready() -> void:
	add_to_group(GROUP_HAUNTABLE)
	if haunt_sound == null:
		haunt_sound = DEFAULT_HAUNT_SOUND
	if effect_sound == null:
		effect_sound = DEFAULT_EFFECT_SOUNDS.get(effect_type)
	_haunt_audio.stream = haunt_sound
	_haunt_audio.volume_db = HAUNT_VOLUME_DB
	if _haunt_audio.stream is AudioStreamMP3:
		(_haunt_audio.stream as AudioStreamMP3).loop = true
	_effect_audio.stream = effect_sound


func _process(delta: float) -> void:
	if _flicker_timer > 0.0:
		_flicker_timer = maxf(0.0, _flicker_timer - delta)
		if _lamp:
			_lamp.light_energy = FLICKER_ENERGY * randf() if _flicker_timer > 0.0 else 0.0
	if possessor != null:
		_twitch_timer -= delta
		if _twitch_timer <= 0.0:
			_twitch_timer = TWITCH_INTERVAL
			_twitch(0.05)


func is_possessed() -> bool:
	return possessor != null


func can_be_haunted() -> bool:
	return possessor == null


## GhostPlayer calls this when a ghost enters the object.
func possess(ghost: GhostPlayer) -> void:
	if possessor != null:
		return
	possessor = ghost
	_twitch_timer = 0.0
	_haunt_audio.play()
	possessed.emit(ghost)


## GhostPlayer calls this when the ghost leaves (B) or is purged (flash).
func release() -> void:
	var ghost := possessor
	if ghost == null:
		return
	possessor = null
	_haunt_audio.stop()
	_flicker_timer = 0.0
	if _lamp:
		_lamp.light_energy = 0.0
	released.emit(ghost)


## A while haunting: fire the prop's effect (flicker / creak / twitch burst).
func trigger_effect() -> void:
	if possessor == null:
		return
	match effect_type:
		EffectType.FLICKER:
			_flicker_timer = FLICKER_DURATION
		EffectType.CREAK:
			_twitch(0.12)
		EffectType.TWITCH:
			_twitch(0.25)
	_effect_audio.play()
	effect_triggered.emit(possessor)


func _twitch(strength: float) -> void:
	if not _prop:
		return
	var tw := _prop.create_tween()
	tw.tween_property(_prop, "rotation", Vector3(randf_range(-strength, strength), randf_range(-strength, strength), randf_range(-strength, strength)), 0.06)
	tw.tween_property(_prop, "rotation", Vector3.ZERO, 0.12)


## Debug/E2E helpers (script vars are not visible to the MCP bridge).
func debug_is_possessed() -> bool:
	return possessor != null


func debug_possessor_path() -> String:
	return possessor.get_path() if is_instance_valid(possessor) else ""


func debug_effect_type() -> int:
	return effect_type


func debug_is_flickering() -> bool:
	return _flicker_timer > 0.0


## Debug/E2E helper: trigger the effect and report the resulting state in one
## call (MCP roundtrips are slower than the flicker window).
func debug_trigger_and_report() -> Dictionary:
	trigger_effect()
	return {
		"possessed": possessor != null,
		"effect_type": effect_type,
		"flicker_timer": _flicker_timer,
	}
