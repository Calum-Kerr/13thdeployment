extends CharacterBody3D
class_name TestPlayer

"""
TestPlayer: A simplified player character for testing enemy behaviors.
"""

# Player properties
@export var move_speed: float = 5.0
@export var health: float = 100.0
@export var max_health: float = 100.0

# Signals
signal health_changed(current_health, max_health)

# State
var is_attacking: bool = false
var attack_cooldown: float = 0.0

# Called when the node enters the scene tree for the first time
func _ready():
    # Add to player group
    add_to_group("player")
    
    # Notify game manager if it exists
    var game_manager = get_node_or_null("/root/GameManager")
    if game_manager and game_manager.has_method("register_player"):
        game_manager.register_player(self)

# Handle physics updates
func _physics_process(delta):
    # Update attack cooldown
    if attack_cooldown > 0:
        attack_cooldown -= delta
        if attack_cooldown <= 0:
            is_attacking = false
    
    # Get input direction
    var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    # Apply movement
    if direction:
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        
        # Look in movement direction
        look_at(global_position + Vector3(direction.x, 0, direction.z), Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0, move_speed)
        velocity.z = move_toward(velocity.z, 0, move_speed)
    
    # Apply gravity
    velocity.y = -0.1
    
    # Move the character
    move_and_slide()
    
    # Handle attack input
    if Input.is_action_just_pressed("ui_accept") and attack_cooldown <= 0:
        _attack()

# Handle taking damage
func take_damage(damage: float, attacker = null):
    health -= damage
    health = max(0, health)
    
    emit_signal("health_changed", health, max_health)
    
    if health <= 0:
        _die()

# Perform attack
func _attack():
    is_attacking = true
    attack_cooldown = 0.5
    
    # Play attack animation
    $AnimationPlayer.play("attack")
    
    # Check for enemies in attack range
    var attack_range = 2.0
    var enemies = get_tree().get_nodes_in_group("enemies")
    enemies.append_array(get_tree().get_nodes_in_group("mini_bosses"))
    
    for enemy in enemies:
        var distance = global_position.distance_to(enemy.global_position)
        if distance <= attack_range:
            # Check if enemy is in front of player
            var to_enemy = (enemy.global_position - global_position).normalized()
            var forward = -global_transform.basis.z
            var dot = to_enemy.dot(forward)
            
            if dot > 0.5:  # Enemy is roughly in front of player
                if enemy.has_method("take_damage"):
                    enemy.take_damage(20.0, self)

# Handle death
func _die():
    # Play death animation
    $AnimationPlayer.play("die")
    
    # Disable controls
    set_physics_process(false)
    
    # Respawn after delay
    await get_tree().create_timer(3.0).timeout
    
    # Reset health and position
    health = max_health
    emit_signal("health_changed", health, max_health)
    
    # Find spawn point
    var spawn_point = get_tree().get_first_node_in_group("player_spawn_point")
    if spawn_point:
        global_position = spawn_point.global_position
    
    # Re-enable controls
    set_physics_process(true)
    
    # Play respawn animation
    $AnimationPlayer.play("respawn")

# Check if player is attacking (for enemy defensive behaviors)
func is_attacking() -> bool:
    return is_attacking 