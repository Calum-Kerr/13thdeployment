extends CharacterBody3D
class_name EnemyBase

"""
EnemyBase: Base class for all enemies in the game.
Implements a state machine for AI behavior and combat mechanics.
"""

# Signal declarations
signal health_changed(current_health: float, max_health: float)
signal enemy_died(souls_reward: int)
signal state_changed(new_state: int)

# Enemy Stats
@export_category("Enemy Stats")
@export var base_health: float = 100.0
@export var base_poise: float = 20.0
@export var souls_reward: int = 100
@export var aggro_range: float = 10.0
@export var attack_range: float = 2.0
@export var movement_speed: float = 3.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 1.5
@export var stagger_threshold: float = 30.0
@export var is_boss: bool = false

# AI Parameters
@export_category("AI Parameters")
@export var patrol_path: NodePath
@export var patrol_points: Array[Vector3] = []
@export var patrol_wait_time: float = 2.0
@export var chase_speed_multiplier: float = 1.5
@export var wander_radius: float = 5.0
@export var perception_angle: float = 120.0  # Degrees
@export var perception_range: float = 15.0

# Runtime variables
var current_health: float
var current_poise: float
var poise_recovery_rate: float = 5.0
var can_attack: bool = true
var target = null
var home_position: Vector3
var current_patrol_index: int = 0
var wander_target: Vector3
var last_attack_time: float = 0.0

# State machine variables
enum EnemyState {IDLE, PATROL, WANDER, CHASE, ATTACK, STAGGERED, DEAD}
var current_state: int = EnemyState.IDLE
var previous_state: int = EnemyState.IDLE

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area3D = $DetectionArea
@onready var hit_box: Area3D = $HitBox
@onready var hurt_box: Area3D = $HurtBox
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var state_timer: Timer = $StateTimer

# Constants
const GRAVITY: float = 9.8

func _ready() -> void:
	"""Initialize the enemy."""
	# Initialize stats
	current_health = base_health
	current_poise = base_poise
	
	# Store initial position as home
	home_position = global_position
	
	# Connect signals
	detection_area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	hit_box.connect("area_entered", Callable(self, "_on_hit_box_area_entered"))
	hurt_box.connect("area_entered", Callable(self, "_on_hurt_box_area_entered"))
	state_timer.connect("timeout", Callable(self, "_on_state_timer_timeout"))
	
	# Set up patrol path if specified
	if patrol_path:
		var path_node = get_node(patrol_path)
		if path_node and path_node.get_child_count() > 0:
			for point in path_node.get_children():
				patrol_points.append(point.global_position)
	
	# Start in patrol state if patrol points exist, otherwise wander
	if patrol_points.size() > 0:
		_change_state(EnemyState.PATROL)
	else:
		_change_state(EnemyState.WANDER)
		_set_wander_target()

func _physics_process(delta: float) -> void:
	"""Handle physics updates including movement and state management."""
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Handle state-specific behavior
	match current_state:
		EnemyState.IDLE:
			_idle_behavior(delta)
		EnemyState.PATROL:
			_patrol_behavior(delta)
		EnemyState.WANDER:
			_wander_behavior(delta)
		EnemyState.CHASE:
			_chase_behavior(delta)
		EnemyState.ATTACK:
			_attack_behavior(delta)
		EnemyState.STAGGERED:
			# No movement during stagger
			velocity.x = 0
			velocity.z = 0
		EnemyState.DEAD:
			# No movement when dead
			velocity = Vector3.ZERO
	
	# Apply movement
	move_and_slide()
	
	# Recover poise over time
	if current_poise < base_poise:
		current_poise += poise_recovery_rate * delta
		current_poise = min(current_poise, base_poise)

func _idle_behavior(delta: float) -> void:
	"""Handle idle state behavior."""
	# In idle state, the enemy stands still and occasionally looks around
	velocity.x = 0
	velocity.z = 0
	
	# Check for player in detection range
	_check_for_player()
	
	# Transition to wander or patrol after a delay
	if state_timer.is_stopped():
		state_timer.start(randf_range(2.0, 4.0))

func _patrol_behavior(delta: float) -> void:
	"""Handle patrol state behavior."""
	if patrol_points.size() == 0:
		_change_state(EnemyState.WANDER)
		return
	
	# Move to the current patrol point
	var target_point = patrol_points[current_patrol_index]
	_navigate_to_position(target_point, movement_speed, delta)
	
	# Check if we've reached the current patrol point
	if global_position.distance_to(target_point) < 0.5:
		# Move to the next patrol point
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		
		# Wait at the patrol point
		_change_state(EnemyState.IDLE)
		state_timer.start(patrol_wait_time)
	
	# Check for player in detection range
	_check_for_player()

func _wander_behavior(delta: float) -> void:
	"""Handle wander state behavior."""
	# Move to the wander target
	_navigate_to_position(wander_target, movement_speed * 0.7, delta)
	
	# Check if we've reached the wander target
	if global_position.distance_to(wander_target) < 0.5:
		# Set a new wander target
		_change_state(EnemyState.IDLE)
		state_timer.start(randf_range(1.0, 3.0))
	
	# Check for player in detection range
	_check_for_player()

func _chase_behavior(delta: float) -> void:
	"""Handle chase state behavior."""
	if not target or not is_instance_valid(target):
		_change_state(EnemyState.WANDER)
		return
	
	# Move towards the target
	_navigate_to_position(target.global_position, movement_speed * chase_speed_multiplier, delta)
	
	# Check if in attack range
	if global_position.distance_to(target.global_position) <= attack_range:
		if can_attack:
			_change_state(EnemyState.ATTACK)
	
	# Check if target is out of aggro range
	if global_position.distance_to(target.global_position) > aggro_range * 1.5:
		target = null
		_change_state(EnemyState.WANDER)

func _attack_behavior(delta: float) -> void:
	"""Handle attack state behavior."""
	if not target or not is_instance_valid(target):
		_change_state(EnemyState.WANDER)
		return
	
	# Face the target
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	
	# Attack logic is handled by animation events
	if can_attack:
		can_attack = false
		
		# Choose an attack based on distance and other factors
		var attack_type = _choose_attack()
		
		# Play attack animation
		animation_player.play(attack_type)
		
		# Attack cooldown
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
		
		# Return to chase state after attack
		if current_state == EnemyState.ATTACK:
			_change_state(EnemyState.CHASE)

func _navigate_to_position(target_pos: Vector3, speed: float, delta: float) -> void:
	"""Navigate to a target position using the navigation system."""
	nav_agent.target_position = target_pos
	
	if nav_agent.is_navigation_finished():
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	# Set velocity based on direction and speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# Face movement direction
	look_at(Vector3(next_pos.x, global_position.y, next_pos.z), Vector3.UP)

func _set_wander_target() -> void:
	"""Set a random wander target within the wander radius."""
	var random_angle = randf() * 2.0 * PI
	var random_radius = randf() * wander_radius
	var offset = Vector3(cos(random_angle) * random_radius, 0, sin(random_angle) * random_radius)
	wander_target = home_position + offset

func _check_for_player() -> void:
	"""Check if the player is within detection range and angle."""
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		
		if distance <= perception_range:
			var direction_to_target = (target.global_position - global_position).normalized()
			var forward_direction = -transform.basis.z.normalized()
			var angle_to_target = rad_to_deg(acos(direction_to_target.dot(forward_direction)))
			
			if angle_to_target <= perception_angle / 2.0 or distance <= aggro_range:
				_change_state(EnemyState.CHASE)

func _choose_attack() -> String:
	"""Choose an attack type based on distance, state, etc."""
	# This can be expanded with more complex logic
	var attack_options = ["attack_1", "attack_2"]
	return attack_options[randi() % attack_options.size()]

func _change_state(new_state: int) -> void:
	"""Change the current state and handle state transitions."""
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	# Handle state entry actions
	match new_state:
		EnemyState.IDLE:
			animation_player.play("idle")
		EnemyState.PATROL:
			animation_player.play("walk")
		EnemyState.WANDER:
			animation_player.play("walk")
			_set_wander_target()
		EnemyState.CHASE:
			animation_player.play("run")
		EnemyState.ATTACK:
			# Attack animation is handled in attack_behavior
			pass
		EnemyState.STAGGERED:
			animation_player.play("stagger")
		EnemyState.DEAD:
			animation_player.play("death")
	
	emit_signal("state_changed", new_state)

func take_damage(damage: float, attacker = null) -> void:
	"""Handle taking damage from an attack."""
	if current_state == EnemyState.DEAD:
		return
	
	# Apply damage
	current_health -= damage
	emit_signal("health_changed", current_health, base_health)
	
	# Reduce poise
	current_poise -= damage * 0.5
	
	# Set attacker as target if not already targeting something
	if attacker and (!target or !is_instance_valid(target)):
		target = attacker
		_change_state(EnemyState.CHASE)
	
	# Check for stagger
	if current_poise <= 0:
		_stagger()
	
	# Check for death
	if current_health <= 0:
		_die()
	else:
		# Play hit animation
		animation_player.play("hit")
		await animation_player.animation_finished
		
		if current_state != EnemyState.DEAD and current_state != EnemyState.STAGGERED:
			_change_state(EnemyState.CHASE)

func _stagger() -> void:
	"""Handle stagger state."""
	_change_state(EnemyState.STAGGERED)
	
	# Reset poise
	current_poise = base_poise * 0.3
	
	# End stagger after animation
	await animation_player.animation_finished
	
	if current_state == EnemyState.STAGGERED:
		_change_state(EnemyState.CHASE)

func _die() -> void:
	"""Handle death state."""
	_change_state(EnemyState.DEAD)
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Emit death signal with souls reward
	emit_signal("enemy_died", souls_reward)
	
	# Remove after death animation
	await animation_player.animation_finished
	queue_free()

func _on_detection_area_body_entered(body: Node3D) -> void:
	"""Handle body entering detection area."""
	if body is PlayerCharacter:
		target = body
		_check_for_player()

func _on_detection_area_body_exited(body: Node3D) -> void:
	"""Handle body exiting detection area."""
	if body is PlayerCharacter and body == target:
		# Don't immediately lose target, check in chase behavior
		pass

func _on_hit_box_area_entered(area: Area3D) -> void:
	"""Handle hit box collisions (enemy attacking player)."""
	if area.is_in_group("player_hurt_box") and current_state == EnemyState.ATTACK:
		var player = area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, self)

func _on_hurt_box_area_entered(area: Area3D) -> void:
	"""Handle hurt box collisions (enemy being hit)."""
	if area.is_in_group("player_hit_box"):
		var player = area.get_parent()
		# Damage calculation would be done by the player's attack system
		# This is just a fallback
		if player and player.has_method("get_attack_damage"):
			var damage = player.get_attack_damage()
			take_damage(damage, player)

func _on_state_timer_timeout() -> void:
	"""Handle state timer timeout."""
	match current_state:
		EnemyState.IDLE:
			if patrol_points.size() > 0:
				_change_state(EnemyState.PATROL)
			else:
				_change_state(EnemyState.WANDER)

# Virtual methods for derived classes to override
func _custom_behavior(delta: float) -> void:
	"""Custom behavior for derived enemy classes."""
	pass

# New methods for setting player reference and finding player
func set_player(player):
	"""Set the player reference directly."""
	target = player
	if target:
		_check_for_player()

func _find_player():
	"""Find the player in the scene."""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		if target:
			_check_for_player()

func _is_player_in_range() -> bool:
	"""Check if the player is within the detection range."""
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		return distance <= perception_range

	return false 