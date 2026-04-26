@tool
class_name PlayParticleSystems
extends Node3D

@export var on_spawn := false
@export var play_particles: bool = false: 
	set(value):
		if value:
			_find_particles()  # Always scan for new particles
			_cleanup_delays()  # Remove deleted particles from the list
			_start_delays()  # Ensure delays exist for new particles
			_play_particles()
		play_particles = false  # Reset the checkbox immediately

@export var delays: Dictionary
@export var cleanDelays: bool = false: 
	set(value):
		if value:
			delays.clear()
		cleanDelays = false
@export var cleanup_after := 1.0

var particle_systems: Array
var running := false

func _ready() -> void:
	if on_spawn and not Engine.is_editor_hint():
		play()

func play():
	if running: return
	play_particles = true
	
	var max_delay = 0.0
	for d in delays.values():
		if d > max_delay:
			max_delay = d
	
	get_tree().create_timer(max_delay + cleanup_after).timeout.connect(func(): queue_free())

func _find_particles():
	particle_systems.clear()  # Always clear and re-detect
	var existing_delays = delays.duplicate()  # Preserve existing delays

	for child in get_children():
		if child is GPUParticles3D or child is HitBox or child is ParticleCallback or child is Timer:
			particle_systems.append(child)
			if not existing_delays.has(child.name):
				existing_delays[child.name] = 0.0  # Assign default delay

	delays = existing_delays  # Restore old delays + new ones

func _cleanup_delays(): # Remove delays for particles that no longer exist
	var valid_particle_names = particle_systems.map(func(p): return p.name)
	for key in delays.keys():
		if key not in valid_particle_names:
			delays.erase(key)  # Remove old particle system references

func _start_delays():
	for particle  in particle_systems:
		if not delays.has(particle.name):
			delays[particle.name] = 0.0  # Keep existing delays, add new ones

func _play_particles():
	running = true
	for particle in particle_systems:
		var delay = delays.get(particle.name, 0.0)
		_playDelay(particle, delay)
		
func _playDelay(ps: Node, delay: float):
	if ps is GPUParticles3D:
		ps.emitting = false  # Reset first (prevents issues)
		await get_tree().create_timer(delay).timeout
		ps.restart()  # Works in play mode
		ps.emitting = true   # Start emitting
	elif ps is HitBox:
		ps.hide()
		await get_tree().create_timer(delay).timeout
		ps.show()
		ps.hit()
	elif ps is ParticleCallback:
		await get_tree().create_timer(delay).timeout
		ps.run()
	elif ps is Timer:
		await get_tree().create_timer(delay).timeout
		ps.start()
