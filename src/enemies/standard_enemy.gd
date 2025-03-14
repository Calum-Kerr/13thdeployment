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
@export var ranged_attack_damage: float = 10.0
@export var ranged_attack_range: float = 8.0
@export var ranged_attack_cooldown: float = 3.0

# Enemy-specific variables
var combo_count: int = 0
var max_combo_attacks: int = 3
var is_blocking: bool = false
var can_use_ranged_attack: bool = true

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

func _physics_process(delta: float) -> void:
	"""Handle physics updates with additional behaviors."""
	super._physics_process(delta)
	
	# Add custom behavior
	_custom_behavior(delta)

func _custom_behavior(delta: float) -> void:
	"""Custom behavior for standard enemy."""
	# Implement defensive behavior when player is attacking
	if current_state == EnemyState.CHASE and target and is_instance_valid(target):
		var player = target as PlayerCharacter
		if player and player.is_attacking():
			_defensive_behavior()
	
	# Handle ranged attacks
	if has_ranged_attack and can_use_ranged_attack and current_state == EnemyState.CHASE:
		var distance_to_target = global_position.distance_to(target.global_position)
		if distance_to_target > attack_range and distance_to_target <= ranged_attack_range:
			_perform_ranged_attack()

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
		
	# Random chance to block or dodge
	var rand = randf()
	
	if rand < block_chance:
		_block()
	elif rand < block_chance + dodge_chance:
		_dodge()

func _block() -> void:
	"""Block incoming attacks."""
	is_blocking = true
	animation_player.play("block")
	
	# Reduce movement speed while blocking
	movement_speed *= 0.5
	
	# End block after a short duration
	await get_tree().create_timer(1.5).timeout
	
	if current_state != EnemyState.DEAD:
		is_blocking = false
		movement_speed *= 2.0  # Restore original speed
		
		if current_state == EnemyState.CHASE:
			animation_player.play("run")

func _dodge() -> void:
	"""Dodge away from player."""
	# Calculate dodge direction (away from player)
	var dodge_direction = (global_position - target.global_position).normalized()
	
	# Apply dodge movement
	velocity = dodge_direction * movement_speed * 2.0
	
	# Play dodge animation
	animation_player.play("dodge")
	
	# Wait for dodge animation to finish
	await animation_player.animation_finished
	
	if current_state != EnemyState.DEAD:
		if current_state == EnemyState.CHASE:
			animation_player.play("run")

func _perform_ranged_attack() -> void:
	"""Perform a ranged attack."""
	if not can_use_ranged_attack:
		return
		
	# Stop movement
	velocity = Vector3.ZERO
	
	# Face the target
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	
	# Play ranged attack animation
	animation_player.play("ranged_attack")
	
	# Disable ranged attacks during cooldown
	can_use_ranged_attack = false
	
	# Create projectile
	await get_tree().create_timer(0.5).timeout  # Wait for animation to reach firing point
	
	if current_state != EnemyState.DEAD and target and is_instance_valid(target):
		_spawn_projectile()
	
	# Wait for cooldown
	await get_tree().create_timer(ranged_attack_cooldown).timeout
	
	can_use_ranged_attack = true

func _spawn_projectile() -> void:
	"""Spawn a projectile for ranged attack."""
	var projectile = preload("res://src/projectiles/enemy_projectile.tscn").instantiate()
	get_tree().current_scene.add_child(projectile)
	
	# Set projectile properties
	projectile.global_position = global_position + Vector3(0, 1.5, 0) - transform.basis.z * 0.5
	projectile.direction = (target.global_position - projectile.global_position).normalized()
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