extends EnemyBase
class_name MiniBoss

# Mini-boss specific stats
var phase_threshold := 0.5 # Health percentage to trigger phase 2
var current_phase := 1
var special_attack_cooldown := 15.0
var special_attack_timer := 0.0
var aoe_attack_range := 5.0
var aoe_attack_damage := 30.0
var dash_speed := 15.0
var dash_duration := 0.5
var dash_cooldown := 8.0
var dash_timer := 0.0
var is_dashing := false
var dash_direction := Vector3.ZERO
var dash_time_remaining := 0.0

# Special attack particles
var special_attack_particles: GPUParticles3D

# Override ready function
func _ready():
    super._ready()
    
    # Set mini-boss specific stats
    base_health = 300.0
    current_health = base_health
    attack_damage = 25.0
    movement_speed = 3.5
    aggro_range = 15.0
    attack_range = 2.0
    attack_cooldown = 1.5
    
    # Get special attack particles
    special_attack_particles = $SpecialAttackParticles
    if special_attack_particles:
        special_attack_particles.emitting = false
    
    # Add to mini-bosses group
    add_to_group("mini_bosses")
    
    # Find player if not already set
    if not target:
        _find_player()

# Override physics process
func _physics_process(delta):
    super._physics_process(delta)
    
    # Update timers
    if special_attack_timer > 0:
        special_attack_timer -= delta
    
    if dash_timer > 0:
        dash_timer -= delta
    
    # Handle dashing state
    if is_dashing:
        dash_time_remaining -= delta
        velocity = dash_direction * dash_speed
        
        if dash_time_remaining <= 0:
            is_dashing = false
            # Reset velocity after dash
            velocity = Vector3.ZERO
    
    # Check for phase transition
    if current_phase == 1 and current_health <= base_health * phase_threshold:
        _transition_to_phase_two()

# Custom behavior for mini-boss
func _custom_behavior(delta: float) -> void:
    # Only perform special attacks if player is detected
    if current_state == EnemyState.CHASE or current_state == EnemyState.ATTACK:
        # Try special attack if cooldown is ready
        if special_attack_timer <= 0 and current_state != EnemyState.STAGGERED:
            var special_attack_chance = 0.3 if current_phase == 1 else 0.5
            if randf() < special_attack_chance:
                _perform_special_attack()
                return
        
        # Try dash attack if cooldown is ready
        if dash_timer <= 0 and current_phase == 2 and current_state != EnemyState.STAGGERED:
            var dash_chance = 0.4
            if randf() < dash_chance and target and target.global_position.distance_to(global_position) > 3.0:
                _perform_dash_attack()
                return

# Transition to phase two with enhanced abilities
func _transition_to_phase_two():
    current_phase = 2
    
    # Play transition animation/effect
    if special_attack_particles:
        special_attack_particles.emitting = true
        await get_tree().create_timer(2.0).timeout
        special_attack_particles.emitting = false
    
    # Enhance stats for phase 2
    attack_damage *= 1.5
    movement_speed *= 1.2
    attack_cooldown *= 0.8
    
    # Emit signal for UI/sound effects
    emit_signal("health_changed", current_health, base_health)

# Perform a special area-of-effect attack
func _perform_special_attack():
    # Set cooldown
    special_attack_timer = special_attack_cooldown
    
    # Change state to special attack
    _change_state(EnemyState.ATTACK)
    
    # Play animation
    if animation_player:
        animation_player.play("special_attack")
        await animation_player.animation_finished
    else:
        # If no animation, wait a moment
        await get_tree().create_timer(1.0).timeout
    
    # Apply AOE damage
    if target and target.global_position.distance_to(global_position) <= aoe_attack_range:
        target.take_damage(aoe_attack_damage, self)
    
    # Visual effect
    if special_attack_particles:
        special_attack_particles.emitting = true
        await get_tree().create_timer(1.0).timeout
        special_attack_particles.emitting = false
    
    # Return to chase state
    _change_state(EnemyState.CHASE)

# Perform a dash attack
func _perform_dash_attack():
    # Set cooldown
    dash_timer = dash_cooldown
    
    # Calculate dash direction towards player
    if target:
        dash_direction = (target.global_position - global_position).normalized()
        dash_direction.y = 0  # Keep dash on horizontal plane
        
        # Start dash
        is_dashing = true
        dash_time_remaining = dash_duration
        
        # Play animation
        if animation_player:
            animation_player.play("dash_attack")
        
        # Wait for dash to complete
        await get_tree().create_timer(dash_duration).timeout
        
        # Attack at the end of dash
        if target and target.global_position.distance_to(global_position) <= attack_range * 1.5:
            target.take_damage(attack_damage * 1.5, self)
        
        # Return to chase state
        is_dashing = false
        _change_state(EnemyState.CHASE)

# Override take damage to add phase-specific behavior
func take_damage(damage: float, attacker = null) -> void:
    # Phase 2 has a chance to reduce damage
    if current_phase == 2:
        var damage_reduction_chance = 0.3
        if randf() < damage_reduction_chance:
            damage *= 0.5
    
    # Call parent method
    super.take_damage(damage, attacker)
    
    # Counter-attack in phase 2 with a chance
    if current_phase == 2 and current_health > 0:
        var counter_chance = 0.4
        if randf() < counter_chance and attacker and attacker.has_method("take_damage"):
            # Quick recovery
            await get_tree().create_timer(0.3).timeout
            
            if is_instance_valid(attacker) and attacker.has_method("take_damage"):
                attacker.take_damage(attack_damage * 0.7, self)

# Handle death with special effects
func _die() -> void:
    # Play death animation with particles
    if special_attack_particles:
        special_attack_particles.emitting = true
    
    # Call parent method
    super._die()
    
    # Add additional death effects
    await get_tree().create_timer(3.0).timeout
    
    # Drop special loot
    # This would connect to your loot system
    emit_signal("enemy_died", 150)  # More souls than standard enemies

# Handle detection area signals
func _on_detection_area_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        target = body
        _check_for_player()

func _on_detection_area_body_exited(body: Node3D) -> void:
    if body.is_in_group("player") and body == target:
        # Don't immediately lose target, check in chase behavior
        pass

# Find player in the scene
func _find_player() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player:
        target = player
        _check_for_player() 