class_name PlayerIndicators
extends Node3D

@export var poison_pulse_speed_min := 3.0
@export var poison_pulse_speed_max := 18.0
@export var poison_pulse_amplitude_min := 0.15
@export var poison_pulse_amplitude_max := 0.3
@export var poison_color_flash_threshold := 0.7

@export var skill_ready_display_time := 1.0

@onready var poison_icon: Label3D = $PoisonIcon
@onready var skill_icon: Label3D = $SkillIcon
@onready var skill_ready_timer: Timer = $SkillReadyTimer

const SINGLE_Y := 0.0
const STACK_TOP_Y := -1.0
const STACK_BOT_Y := 0.0

var _poison_timer: Timer
var _poison_pulse_time := 0.0

func setup(poison_timer: Timer) -> void:
	_poison_timer = poison_timer
	skill_ready_timer.timeout.connect(func():
		skill_icon.hide()
		_restack()
	)
	hide_poison()
	set_skill_ready(FPSPlayer.Skill.NONE)

func show_poison() -> void:
	_poison_pulse_time = 0.0
	poison_icon.scale = Vector3.ONE
	poison_icon.modulate = Color.WHITE
	poison_icon.show()
	_restack()

func hide_poison() -> void:
	poison_icon.hide()
	_restack()

func set_skill_ready(skill: FPSPlayer.Skill) -> void:
	match skill:
		#FPSPlayer.Skill.DASH:
			#skill_icon.text = "💨"
			#skill_icon.show()
			#skill_ready_timer.start(skill_ready_display_time)
		#FPSPlayer.Skill.SHIELD:
			#skill_icon.text = "🛡️"
			#skill_icon.show()
			#skill_ready_timer.start(skill_ready_display_time)
		_:
			skill_ready_timer.stop()
			skill_icon.hide()
	_restack()

func _restack() -> void:
	var both := poison_icon.visible and skill_icon.visible
	poison_icon.position.y = STACK_BOT_Y if both else SINGLE_Y
	skill_icon.position.y = STACK_TOP_Y if both else SINGLE_Y

func _process(delta: float) -> void:
	if _poison_timer == null or _poison_timer.is_stopped() or not poison_icon.visible:
		_poison_pulse_time = 0.0
		poison_icon.scale = Vector3.ONE
		poison_icon.modulate = Color.WHITE
		return

	_poison_pulse_time += delta

	var progress := 1.0 - (_poison_timer.time_left / _poison_timer.wait_time)
	var spd := lerpf(poison_pulse_speed_min, poison_pulse_speed_max, progress)
	var amplitude := lerpf(poison_pulse_amplitude_min, poison_pulse_amplitude_max, progress)
	var s := 1.0 + amplitude * sin(_poison_pulse_time * spd)
	poison_icon.scale = Vector3.ONE * s

	if progress > poison_color_flash_threshold:
		var flash := (sin(_poison_pulse_time * spd) + 1.0) / 2.0
		var flash_progress := (progress - poison_color_flash_threshold) / (1.0 - poison_color_flash_threshold)
		poison_icon.modulate = Color.WHITE.lerp(Color.RED, flash * flash_progress)
	else:
		poison_icon.modulate = Color.WHITE
