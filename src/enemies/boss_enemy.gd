extends EnemyBase
class_name BossEnemy

"""
BossEnemy: Extended enemy class for boss encounters.
Features multiple phases, special attacks, and more complex behavior.
"""

# Boss-specific signals
signal phase_changed(phase: int)
signal special_attack_started(attack_name: String)
signal special_attack_ended(attack_name: String)

# Boss Parameters
@export_category("Boss Parameters")
@export var boss_name: String = "Unnamed Boss"
@export var phase_health_thresholds: Array[float] = [0.7, 0.4, 0.15]  # Percentage of health for phase transitions
@export var music_track: String = ""
@export var intro_cutscene: String = ""
@export var death_cutscene: String = ""

# Special Attacks
@export_category("Special Attacks")
@export var special_attack_cooldown: float = 15.0
@export var special_attack_chance: float = 0.3
@export var phase_specific_attacks: Dictionary = {
	1: ["ground_slam", "charge"],
	2: ["ground_slam", "charge", "summon_minions"],
	3: ["ground_slam", "charge", "summon_minions", "area_explosion"]
}

# Runtime variables
var current_phase: int = 1
var can_use_special_attack: bool = true
var special_attack_timer: float = 0.0
var phase_transition_active: bool = false
var minions: Array = []
var max_minions: int = 3

# Additional node references
@onready var special_attack_area: Area3D = $SpecialAttackArea
@onready var phase_transition_particles: GPUParticles3D = $PhaseTransitionParticles
@onready var boss_ui: Control = $BossUI

func _ready() -> void:
	"""Initialize the boss enemy."""
	# Call parent _ready
	super._ready()
	
	# Set boss flag
	is_boss = true
	
	# Initialize boss-specific components
	if boss_ui:
		boss_ui.setup(boss_name, base_health)
	
	# Connect additional signals
	special_attack_area.connect("body_entered", Callable(self, "_on_special_attack_area_body_entered"))

func _physics_process(delta: float) -> void:
	"""Handle physics updates including boss-specific behavior."""
	# Call parent _physics_process
	super._physics_process(delta)
	
	# Handle special attack cooldown
	if not can_use_special_attack:
		special_attack_timer += delta
		if special_attack_timer >= special_attack_cooldown:
			can_use_special_attack = true
			special_attack_timer = 0.0
	
	# Boss-specific custom behavior
	_boss_custom_behavior(delta)

func _boss_custom_behavior(delta: float) -> void:
	"""Boss-specific behavior based on current phase and state."""
	# Only perform special behavior in combat states
	if current_state != EnemyState.CHASE and current_state != EnemyState.ATTACK:
		return
	
	# Check for phase transitions
	_check_phase_transition()
	
	# Consider using special attack if in chase state and not in transition
	if current_state == EnemyState.CHASE and can_use_special_attack and not phase_transition_active:
		if randf() < special_attack_chance * delta:
			_use_special_attack()

func _check_phase_transition() -> void:
	"""Check if boss should transition to a new phase based on health."""
	if phase_transition_active:
		return
	
	var health_percentage = current_health / base_health
	var new_phase = current_phase
	
	# Determine which phase we should be in
	for i in range(phase_health_thresholds.size()):
		if health_percentage <= phase_health_thresholds[i] and current_phase <= i + 1:
			new_phase = i + 2  # Phase 1 is default, so thresholds trigger phase 2, 3, etc.
	
	# If we need to change phase
	if new_phase != current_phase:
		_transition_to_phase(new_phase)

func _transition_to_phase(new_phase: int) -> void:
	"""Handle transition to a new boss phase."""
	phase_transition_active = true
	
	# Store previous state to return to after transition
	var previous_state = current_state
	
	# Enter staggered state during transition
	_change_state(EnemyState.STAGGERED)
	
	# Play transition effects
	animation_player.play("phase_transition")
	phase_transition_particles.emitting = true
	
	# Wait for transition animation
	await animation_player.animation_finished
	
	# Update phase
	current_phase = new_phase
	emit_signal("phase_changed", current_phase)
	
	# Adjust stats based on new phase
	_adjust_stats_for_phase()
	
	# Return to previous state
	if previous_state == EnemyState.DEAD:
		_change_state(EnemyState.CHASE)
	else:
		_change_state(previous_state)
	
	phase_transition_active = false

func _adjust_stats_for_phase() -> void:
	"""Adjust boss stats based on current phase."""
	match current_phase:
		2:
			# Phase 2 adjustments
			attack_damage *= 1.2
			movement_speed *= 1.1
			attack_cooldown *= 0.9
		3:
			# Phase 3 adjustments
			attack_damage *= 1.4
			movement_speed *= 1.2
			attack_cooldown *= 0.8
		4:
			# Final phase adjustments
			attack_damage *= 1.6
			movement_speed *= 1.3
			attack_cooldown *= 0.7

func _use_special_attack() -> void:
	"""Use a special attack based on current phase."""
	can_use_special_attack = false
	special_attack_timer = 0.0
	
	# Get available attacks for current phase
	var available_attacks = phase_specific_attacks.get(current_phase, ["ground_slam"])
	
	# Choose a random attack
	var attack_name = available_attacks[randi() % available_attacks.size()]
	
	# Execute the chosen attack
	match attack_name:
		"ground_slam":
			_special_attack_ground_slam()
		"charge":
			_special_attack_charge()
		"summon_minions":
			_special_attack_summon_minions()
		"area_explosion":
			_special_attack_area_explosion()

func _special_attack_ground_slam() -> void:
	"""Perform a ground slam attack."""
	emit_signal("special_attack_started", "ground_slam")
	
	# Enter attack state
	_change_state(EnemyState.ATTACK)
	
	# Play ground slam animation
	animation_player.play("special_ground_slam")
	
	# Wait for animation to reach impact frame
	await get_tree().create_timer(1.0).timeout
	
	# Apply damage in area
	var bodies = special_attack_area.get_overlapping_bodies()
	for body in bodies:
		if body is PlayerCharacter:
			body.take_damage(attack_damage * 1.5, self)
	
	# Wait for animation to finish
	await animation_player.animation_finished
	
	emit_signal("special_attack_ended", "ground_slam")
	
	if current_state == EnemyState.ATTACK:
		_change_state(EnemyState.CHASE)

func _special_attack_charge() -> void:
	"""Perform a charging attack."""
	emit_signal("special_attack_started", "charge")
	
	# Enter attack state
	_change_state(EnemyState.ATTACK)
	
	# Store target position
	var target_position = target.global_position if target and is_instance_valid(target) else global_position
	
	# Play charge preparation animation
	animation_player.play("special_charge_prepare")
	await animation_player.animation_finished
	
	# Play charge animation
	animation_player.play("special_charge")
	
	# Charge toward target position
	var charge_direction = (target_position - global_position).normalized()
	charge_direction.y = 0
	
	var charge_speed = movement_speed * 3.0
	var charge_duration = 1.0
	var elapsed_time = 0.0
	
	while elapsed_time < charge_duration:
		var delta = get_process_delta_time()
		elapsed_time += delta
		
		velocity = charge_direction * charge_speed
		move_and_slide()
		
		# Check for collision with player
		var collision = move_and_collide(Vector3.ZERO, true, true, true)
		if collision and collision.get_collider() is PlayerCharacter:
			collision.get_collider().take_damage(attack_damage * 2.0, self)
		
		await get_tree().process_frame
	
	# Play charge end animation
	animation_player.play("special_charge_end")
	await animation_player.animation_finished
	
	emit_signal("special_attack_ended", "charge")
	
	if current_state == EnemyState.ATTACK:
		_change_state(EnemyState.CHASE)

func _special_attack_summon_minions() -> void:
	"""Summon minion enemies to assist."""
	emit_signal("special_attack_started", "summon_minions")
	
	# Enter attack state
	_change_state(EnemyState.ATTACK)
	
	# Play summon animation
	animation_player.play("special_summon")
	
	# Wait for animation to reach summon frame
	await get_tree().create_timer(1.5).timeout
	
	# Clean up any dead minions from the array
	minions = minions.filter(func(minion): return is_instance_valid(minion))
	
	# Summon minions if we're below the maximum
	var minions_to_summon = max_minions - minions.size()
	
	for i in range(minions_to_summon):
		# Calculate spawn position
		var spawn_angle = 2.0 * PI * i / minions_to_summon
		var spawn_distance = 3.0
		var spawn_offset = Vector3(cos(spawn_angle) * spawn_distance, 0, sin(spawn_angle) * spawn_distance)
		var spawn_position = global_position + spawn_offset
		
		# Create minion instance
		var minion = _create_minion(spawn_position)
		if minion:
			minions.append(minion)
	
	# Wait for animation to finish
	await animation_player.animation_finished
	
	emit_signal("special_attack_ended", "summon_minions")
	
	if current_state == EnemyState.ATTACK:
		_change_state(EnemyState.CHASE)

func _special_attack_area_explosion() -> void:
	"""Perform an area explosion attack."""
	emit_signal("special_attack_started", "area_explosion")
	
	# Enter attack state
	_change_state(EnemyState.ATTACK)
	
	# Play explosion animation
	animation_player.play("special_explosion")
	
	# Wait for animation to reach explosion frame
	await get_tree().create_timer(2.0).timeout
	
	# Apply damage in large area
	var bodies = special_attack_area.get_overlapping_bodies()
	for body in bodies:
		if body is PlayerCharacter:
			body.take_damage(attack_damage * 2.0, self)
	
	# Wait for animation to finish
	await animation_player.animation_finished
	
	emit_signal("special_attack_ended", "area_explosion")
	
	if current_state == EnemyState.ATTACK:
		_change_state(EnemyState.CHASE)

func _create_minion(spawn_position: Vector3):
	"""Create a minion enemy at the specified position."""
	# This would be implemented to instantiate an actual minion scene
	# For now, we'll return null as a placeholder
	return null

func _die() -> void:
	"""Handle boss death with additional effects."""
	# Call parent _die
	super._die()
	
	# Play death cutscene if available
	if death_cutscene != "":
		# This would trigger the cutscene playback
		pass

func _on_special_attack_area_body_entered(body: Node3D) -> void:
	"""Handle body entering special attack area."""
	# This can be used for special attack targeting or other effects
	pass

# Override parent methods as needed
func _choose_attack() -> String:
	"""Choose an attack based on current phase and distance."""
	var attack_options = []
	
	# Basic attacks available in all phases
	attack_options.append("attack_1")
	attack_options.append("attack_2")
	
	# Add phase-specific basic attacks
	match current_phase:
		2:
			attack_options.append("attack_3")
		3, 4:
			attack_options.append("attack_3")
			attack_options.append("attack_4")
	
	return attack_options[randi() % attack_options.size()] 