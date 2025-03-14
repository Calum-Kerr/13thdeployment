extends EnemyBase
class_name StandardEnemy

"""
StandardEnemy: A standard enemy with basic attack patterns.
Extends the base enemy class with specific behaviors.
"""

# Enemy-specific stats
@export_category("Standard Enemy Stats")
@export var attack_combo_chance: float = 0.4
@export var dodge_chance: float = 0.2
@export var block_chance: float = 0.3
@export var has_ranged_attack: bool = false
@export var ranged_attack_damage: float = 8.0
@export var ranged_attack_range: float = 8.0
@export var ranged_attack_cooldown: float = 5.0
@export var ranged_attack_chance: float = 0.3

# Enemy-specific variables
var combo_count: int = 0
var max_combo_attacks: int = 3
var is_blocking: bool = false
var can_use_ranged_attack: bool = true
var block_timer: float = 0.0
var block_cooldown: float = 3.0
var ranged_attack_timer: float = 0.0
var player_detected: bool = false
var pursuit_timer: float = 0.0
var pursuit_duration: float = 5.0

# Additional state for this enemy type
enum StandardEnemyState {BLOCK, DODGE, RANGED_ATTACK}

func _ready() -> void:
	"""Initialize the standard enemy."""
	super._ready()
	
	# Adjust base stats based on enemy type
	movement_speed *= 1.1  # Slightly faster than base
	
	# Set up additional animations if needed
	if animation_player.has_animation("block"):
		animation_player.get_animation("block").loop_mode = Animation.LOOP_NONE
	
	if animation_player.has_animation("dodge"):
		animation_player.get_animation("dodge").loop_mode = Animation.LOOP_NONE
	
	# Set standard enemy specific stats
	base_health = 100.0
	current_health = base_health
	attack_damage = 15.0
	attack_range = 1.8
	attack_cooldown = 1.2
	
	# Add to standard enemies group
	add_to_group("enemies")
	
	# Find player if not already set
	if not target:
		_find_player()

func _physics_process(delta: float) -> void:
	"""Handle physics updates with additional behaviors."""
	super._physics_process(delta)
	
	# Update block timer
	if block_timer > 0:
		block_timer -= delta
		if block_timer <= 0:
			is_blocking = false
	
	# Update ranged attack timer
	if ranged_attack_timer > 0:
		ranged_attack_timer -= delta
		if ranged_attack_timer <= 0:
			can_use_ranged_attack = true
	
	# Add custom behavior
	_custom_behavior(delta)

func _custom_behavior(delta: float) -> void:
	"""Custom behavior for standard enemy."""
	# If player is attacking, consider defensive behavior
	if target and target.has_method("is_attacking") and target.is_attacking():
		if current_state != EnemyState.STAGGERED and current_state != EnemyState.DEAD:
			_defensive_behavior()
			return
	
	# Consider ranged attack if available
	if has_ranged_attack and can_use_ranged_attack and target:
		var distance = global_position.distance_to(target.global_position)
		if distance > attack_range and distance <= ranged_attack_range:
			if randf() < ranged_attack_chance:
				_perform_ranged_attack()
				return

func _choose_attack() -> String:
	"""Choose an attack type with possible combos."""
	var attack_options = ["attack_1", "attack_2", "attack_3"]
	
	# Check for combo opportunity
	if combo_count > 0 and combo_count < max_combo_attacks:
		combo_count += 1
		return "attack_combo_" + str(combo_count)
	
	# Start new combo?
	if randf() <= attack_combo_chance:
		combo_count = 1
		return "attack_combo_1"
	
	# Reset combo counter
	combo_count = 0
	
	# Return random attack
	return attack_options[randi() % attack_options.size()]

func _defensive_behavior() -> void:
	"""Handle defensive behavior when player is attacking."""
	if is_blocking:
		return
		
	# Choose between blocking and dodging
	var total_chance = dodge_chance + block_chance
	var random_value = randf() * total_chance
	
	if random_value < dodge_chance:
		_dodge()
	elif random_value < total_chance and block_timer <= 0:
		_block()

func _block() -> void:
	"""Block incoming attacks."""
	if block_timer <= 0:
		is_blocking = true
		block_timer = 1.0
		
		# Play block animation
		if animation_player:
			animation_player.play("block")
		
		# Set block cooldown
		await get_tree().create_timer(1.0).timeout
		is_blocking = false
		block_timer = block_cooldown

func _dodge() -> void:
	"""Dodge away from player."""
	if target:
		# Calculate dodge direction (away from player)
		var dodge_dir = (global_position - target.global_position).normalized()
		
		# Apply dodge movement
		velocity = dodge_dir * movement_speed * 2.0
		
		# Play dodge animation
		if animation_player:
			animation_player.play("dodge")
		
		# Move character
		move_and_slide()
		
		# Return to chase state after dodge
		await get_tree().create_timer(0.5).timeout
		_change_state(EnemyState.CHASE)

func _perform_ranged_attack() -> void:
	"""Perform a ranged attack."""
	# Set cooldown
	can_use_ranged_attack = false
	ranged_attack_timer = ranged_attack_cooldown
	
	# Change state to attack
	_change_state(EnemyState.ATTACK)
	
	# Play ranged attack animation
	if animation_player:
		animation_player.play("ranged_attack")
		await animation_player.animation_finished
	else:
		# If no animation, wait a moment
		await get_tree().create_timer(0.8).timeout
	
	# Spawn projectile
	_spawn_projectile()
	
	# Return to chase state
	_change_state(EnemyState.CHASE)

func _spawn_projectile() -> void:
	"""Spawn a projectile for ranged attack."""
	if target:
		# Get projectile scene
		var projectile_scene = load("res://src/projectiles/enemy_projectile.tscn")
		if projectile_scene:
			# Create projectile instance
			var projectile = projectile_scene.instantiate()
			get_tree().current_scene.add_child(projectile)
			
			# Set projectile properties
			var spawn_point = $ProjectileSpawnPoint if has_node("ProjectileSpawnPoint") else self
			projectile.global_position = spawn_point.global_position
			
			# Calculate direction to player
			var direction = (target.global_position - spawn_point.global_position).normalized()
			
			# Set projectile direction and damage
			if projectile.has_method("initialize"):
				projectile.initialize(direction, ranged_attack_damage, self)
			else:
				# Fallback if initialize method doesn't exist
				projectile.direction = direction
				projectile.damage = ranged_attack_damage
				projectile.source = self

func take_damage(damage: float, attacker = null) -> void:
	"""Handle taking damage with blocking mechanic."""
	if is_blocking:
		# Reduce damage when blocking
		damage *= 0.3
		
		# Play block impact animation/effect
		if animation_player.has_animation("block_impact"):
			animation_player.play("block_impact")
	
	# Call parent method
	super.take_damage(damage, attacker)
	
	# End blocking if staggered or dead
	if current_state == EnemyState.STAGGERED or current_state == EnemyState.DEAD:
		is_blocking = false 

# Handle detection area signals
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		target = body
		player_detected = true
		_change_state(EnemyState.CHASE)

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body == target:
		player_detected = false
		pursuit_timer = pursuit_duration 