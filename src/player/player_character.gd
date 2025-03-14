extends CharacterBody3D
class_name PlayerCharacter

"""
PlayerCharacter: Main player controller implementing Soulsborne-style mechanics.
This class handles player movement, combat, stats, and interactions.
"""

# Signal declarations
signal health_changed(current_health: float, max_health: float)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal souls_changed(souls: int)
signal player_died()
signal weapon_changed(weapon_data: Dictionary)

# Character Stats
@export_category("Character Stats")
@export var base_health: float = 100.0
@export var base_stamina: float = 100.0
@export var base_equip_load: float = 50.0
@export var base_poise: float = 10.0

# Attributes
@export_category("Attributes")
@export var strength: int = 10
@export var dexterity: int = 10
@export var vitality: int = 10
@export var endurance: int = 10
@export var intelligence: int = 10
@export var faith: int = 10

# Movement Parameters
@export_category("Movement")
@export var walk_speed: float = 3.0
@export var run_speed: float = 5.0
@export var dodge_speed: float = 8.0
@export var dodge_duration: float = 0.5
@export var dodge_cooldown: float = 0.8
@export var dodge_i_frames: float = 0.3
@export var gravity_multiplier: float = 1.8
@export var jump_height: float = 1.5
@export var air_control: float = 0.3

# Combat Parameters
@export_category("Combat")
@export var light_attack_stamina_cost: float = 15.0
@export var heavy_attack_stamina_cost: float = 30.0
@export var block_stamina_cost: float = 5.0
@export var parry_window: float = 0.2
@export var parry_cooldown: float = 1.0
@export var attack_cooldown: float = 0.5

# Equipment
var current_weapon: Dictionary = {}
var current_armor: Dictionary = {}
var current_equip_load: float = 0.0
var equip_load_percentage: float = 0.0

# Runtime variables
var current_health: float
var current_stamina: float
var stamina_regen_rate: float = 20.0
var souls: int = 0
var last_death_position: Vector3
var lost_souls: int = 0

# State machine variables
enum PlayerState {IDLE, WALKING, RUNNING, ATTACKING, BLOCKING, DODGING, PARRYING, STAGGERED, DEAD}
var current_state: int = PlayerState.IDLE
var can_attack: bool = true
var can_dodge: bool = true
var can_parry: bool = true
var is_invulnerable: bool = false
var is_locked_on: bool = false
var lock_on_target = null

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var weapon_pivot: Node3D = $WeaponPivot
@onready var hit_box: Area3D = $HitBox
@onready var hurt_box: Area3D = $HurtBox

# Constants
const GRAVITY: float = 9.8

func _ready() -> void:
	"""Initialize the player character."""
	# Initialize stats based on attributes
	_calculate_stats()
	
	# Set current values to maximum
	current_health = get_max_health()
	current_stamina = get_max_stamina()
	
	# Connect signals
	hit_box.connect("area_entered", Callable(self, "_on_hit_box_area_entered"))
	hurt_box.connect("area_entered", Callable(self, "_on_hurt_box_area_entered"))

func _physics_process(delta: float) -> void:
	"""Handle physics updates including movement and state management."""
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * gravity_multiplier * delta
	
	# Handle movement based on current state
	match current_state:
		PlayerState.IDLE, PlayerState.WALKING, PlayerState.RUNNING:
			_handle_movement(delta)
		PlayerState.DODGING:
			_handle_dodge(delta)
		PlayerState.ATTACKING:
			_handle_attack(delta)
		PlayerState.BLOCKING:
			_handle_block(delta)
		PlayerState.STAGGERED:
			# No movement during stagger
			velocity.x = 0
			velocity.z = 0
		PlayerState.DEAD:
			# No movement when dead
			velocity = Vector3.ZERO
	
	# Apply movement
	move_and_slide()
	
	# Handle stamina regeneration
	if current_state != PlayerState.RUNNING and current_state != PlayerState.ATTACKING:
		_regenerate_stamina(delta)

func _input(event: InputEvent) -> void:
	"""Process player input for actions."""
	if current_state == PlayerState.DEAD:
		return
	
	# Attack inputs
	if event.is_action_pressed("attack_light") and can_attack:
		_light_attack()
	
	if event.is_action_pressed("attack_heavy") and can_attack:
		_heavy_attack()
	
	# Dodge/Roll
	if event.is_action_pressed("dodge") and can_dodge:
		_dodge()
	
	# Block/Parry
	if event.is_action_pressed("block"):
		_start_block()
	elif event.is_action_released("block"):
		_end_block()
	
	if event.is_action_pressed("parry") and can_parry:
		_parry()
	
	# Lock-on
	if event.is_action_pressed("lock_on"):
		_toggle_lock_on()

func _handle_movement(delta: float) -> void:
	"""Handle player movement based on input."""
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Determine if running or walking
		var is_running = Input.is_action_pressed("run") and current_stamina > 0
		
		if is_running:
			current_state = PlayerState.RUNNING
			velocity.x = direction.x * run_speed
			velocity.z = direction.z * run_speed
			
			# Consume stamina while running
			current_stamina -= 10.0 * delta
			current_stamina = max(0, current_stamina)
			emit_signal("stamina_changed", current_stamina, get_max_stamina())
			
			if current_stamina <= 0:
				# Too exhausted to run
				is_running = false
		else:
			current_state = PlayerState.WALKING
			velocity.x = direction.x * walk_speed
			velocity.z = direction.z * walk_speed
		
		# Face movement direction
		if not is_locked_on:
			look_at(global_position + Vector3(direction.x, 0, direction.z), Vector3.UP)
	else:
		current_state = PlayerState.IDLE
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)

func _handle_dodge(delta: float) -> void:
	"""Handle dodge/roll movement."""
	# Dodge movement is handled by the dodge function and animation
	pass

func _handle_attack(delta: float) -> void:
	"""Handle attack movement and effects."""
	# Attack movement is handled by the attack functions and animations
	pass

func _handle_block(delta: float) -> void:
	"""Handle blocking state."""
	# Reduce movement speed while blocking
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * walk_speed * 0.5
		velocity.z = direction.z * walk_speed * 0.5
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)
	
	# Consume stamina while blocking
	current_stamina -= block_stamina_cost * delta
	current_stamina = max(0, current_stamina)
	emit_signal("stamina_changed", current_stamina, get_max_stamina())
	
	if current_stamina <= 0:
		# Too exhausted to block
		_end_block()

func _light_attack() -> void:
	"""Perform a light attack."""
	if current_stamina < light_attack_stamina_cost:
		# Not enough stamina
		return
	
	current_state = PlayerState.ATTACKING
	can_attack = false
	
	# Consume stamina
	current_stamina -= light_attack_stamina_cost
	emit_signal("stamina_changed", current_stamina, get_max_stamina())
	
	# Play attack animation
	animation_player.play("light_attack")
	
	# Enable hitbox during attack animation at the appropriate frame
	# This will be handled by animation events
	
	# Set cooldown timer
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func _heavy_attack() -> void:
	"""Perform a heavy attack."""
	if current_stamina < heavy_attack_stamina_cost:
		# Not enough stamina
		return
	
	current_state = PlayerState.ATTACKING
	can_attack = false
	
	# Consume stamina
	current_stamina -= heavy_attack_stamina_cost
	emit_signal("stamina_changed", current_stamina, get_max_stamina())
	
	# Play attack animation
	animation_player.play("heavy_attack")
	
	# Enable hitbox during attack animation at the appropriate frame
	# This will be handled by animation events
	
	# Set cooldown timer
	await get_tree().create_timer(attack_cooldown * 1.5).timeout
	can_attack = true
	
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func _dodge() -> void:
	"""Perform a dodge roll."""
	if current_stamina < 20.0:
		# Not enough stamina
		return
	
	current_state = PlayerState.DODGING
	can_dodge = false
	
	# Consume stamina
	current_stamina -= 20.0
	emit_signal("stamina_changed", current_stamina, get_max_stamina())
	
	# Set invulnerability frames
	is_invulnerable = true
	await get_tree().create_timer(dodge_i_frames).timeout
	is_invulnerable = false
	
	# Play dodge animation
	animation_player.play("dodge")
	
	# Apply dodge movement
	var dodge_direction = -transform.basis.z
	if Input.is_action_pressed("move_left"):
		dodge_direction = -transform.basis.x
	elif Input.is_action_pressed("move_right"):
		dodge_direction = transform.basis.x
	elif Input.is_action_pressed("move_backward"):
		dodge_direction = transform.basis.z
	
	velocity = dodge_direction * dodge_speed
	
	# End dodge after duration
	await get_tree().create_timer(dodge_duration).timeout
	
	if current_state == PlayerState.DODGING:
		current_state = PlayerState.IDLE
	
	# Set cooldown timer
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true

func _start_block() -> void:
	"""Start blocking."""
	current_state = PlayerState.BLOCKING
	animation_player.play("block")

func _end_block() -> void:
	"""End blocking."""
	if current_state == PlayerState.BLOCKING:
		current_state = PlayerState.IDLE
		animation_player.play("idle")

func _parry() -> void:
	"""Attempt a parry."""
	if current_stamina < 15.0:
		# Not enough stamina
		return
	
	can_parry = false
	
	# Consume stamina
	current_stamina -= 15.0
	emit_signal("stamina_changed", current_stamina, get_max_stamina())
	
	# Play parry animation
	animation_player.play("parry")
	
	# Parry window
	await get_tree().create_timer(parry_window).timeout
	
	# Set cooldown timer
	await get_tree().create_timer(parry_cooldown).timeout
	can_parry = true

func _toggle_lock_on() -> void:
	"""Toggle lock-on targeting."""
	is_locked_on = !is_locked_on
	
	if is_locked_on:
		# Find nearest enemy to lock onto
		_find_lock_on_target()
	else:
		lock_on_target = null

func _find_lock_on_target() -> void:
	"""Find the nearest valid enemy to lock onto."""
	# This would scan for enemies in range and select the closest one
	# For now, we'll leave this as a placeholder
	pass

func _regenerate_stamina(delta: float) -> void:
	"""Regenerate stamina over time."""
	if current_stamina < get_max_stamina():
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(current_stamina, get_max_stamina())
		emit_signal("stamina_changed", current_stamina, get_max_stamina())

func _calculate_stats() -> void:
	"""Calculate derived stats based on attributes."""
	# These formulas can be adjusted for balance
	current_equip_load = 0.0  # Will be calculated based on equipped items
	equip_load_percentage = current_equip_load / get_max_equip_load()

func take_damage(damage: float, attacker = null) -> void:
	"""Handle taking damage from an attack."""
	if is_invulnerable or current_state == PlayerState.DEAD:
		return
	
	# Check if blocking
	if current_state == PlayerState.BLOCKING:
		# Calculate damage reduction based on shield stats and angle
		var block_efficiency = 0.7  # Placeholder value
		damage *= (1.0 - block_efficiency)
		
		# Consume stamina based on blocked damage
		var stamina_damage = damage * 0.5
		current_stamina -= stamina_damage
		current_stamina = max(0, current_stamina)
		emit_signal("stamina_changed", current_stamina, get_max_stamina())
		
		if current_stamina <= 0:
			# Guard broken
			_guard_break()
	
	# Apply damage
	current_health -= damage
	emit_signal("health_changed", current_health, get_max_health())
	
	# Check for death
	if current_health <= 0:
		_die()
	else:
		# Play hit animation
		animation_player.play("hit")
		
		# Briefly enter staggered state
		var previous_state = current_state
		current_state = PlayerState.STAGGERED
		await get_tree().create_timer(0.5).timeout
		
		if current_state == PlayerState.STAGGERED:
			current_state = previous_state

func _guard_break() -> void:
	"""Handle guard break state."""
	current_state = PlayerState.STAGGERED
	animation_player.play("guard_break")
	
	# End staggered state after delay
	await get_tree().create_timer(1.5).timeout
	
	if current_state == PlayerState.STAGGERED:
		current_state = PlayerState.IDLE

func _die() -> void:
	"""Handle player death."""
	current_state = PlayerState.DEAD
	animation_player.play("death")
	
	# Drop souls at death location
	last_death_position = global_position
	lost_souls = souls
	souls = 0
	
	emit_signal("souls_changed", souls)
	emit_signal("player_died")

func recover_souls() -> void:
	"""Recover souls from last death location."""
	souls += lost_souls
	lost_souls = 0
	emit_signal("souls_changed", souls)

func heal(amount: float) -> void:
	"""Heal the player."""
	current_health += amount
	current_health = min(current_health, get_max_health())
	emit_signal("health_changed", current_health, get_max_health())

func add_souls(amount: int) -> void:
	"""Add souls to the player's total."""
	souls += amount
	emit_signal("souls_changed", souls)

func get_max_health() -> float:
	"""Calculate max health based on vitality."""
	return base_health + (vitality * 10.0)

func get_max_stamina() -> float:
	"""Calculate max stamina based on endurance."""
	return base_stamina + (endurance * 5.0)

func get_max_equip_load() -> float:
	"""Calculate max equipment load based on vitality."""
	return base_equip_load + (vitality * 1.5)

func _on_hit_box_area_entered(area: Area3D) -> void:
	"""Handle hit box collisions (player attacking enemies)."""
	if area.is_in_group("enemy_hurt_box") and current_state == PlayerState.ATTACKING:
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			# Calculate damage based on weapon stats and attributes
			var damage = 20.0  # Placeholder value
			enemy.take_damage(damage, self)

func _on_hurt_box_area_entered(area: Area3D) -> void:
	"""Handle hurt box collisions (player being hit)."""
	if area.is_in_group("enemy_hit_box"):
		var enemy = area.get_parent()
		# Calculate damage based on enemy attack
		var damage = 15.0  # Placeholder value
		take_damage(damage, enemy)

func equip_weapon(weapon_data: Dictionary) -> void:
	"""Equip a new weapon."""
	current_weapon = weapon_data
	# Update equip load
	current_equip_load += weapon_data.get("weight", 0.0)
	equip_load_percentage = current_equip_load / get_max_equip_load()
	
	# Update weapon model
	# This would load and attach the weapon model
	
	emit_signal("weapon_changed", weapon_data)

func equip_armor(armor_data: Dictionary) -> void:
	"""Equip a new armor piece."""
	current_armor = armor_data
	# Update equip load
	current_equip_load += armor_data.get("weight", 0.0)
	equip_load_percentage = current_equip_load / get_max_equip_load()
	
	# Update armor model
	# This would load and attach the armor model 