extends Node

"""
EnemyTestController: Debug tool for testing enemy behaviors.
Allows triggering various enemy actions and displaying debug information.
"""

# References
var enemies = []
var mini_boss = null
var debug_overlay = null
var debug_enabled = false
var overview_camera = null
var player_camera = null
var current_camera = "player"

# Called when the node enters the scene tree for the first time
func _ready():
    # Find all enemies in the scene
    await get_tree().create_timer(0.5).timeout
    _find_enemies()
    
    # Create debug overlay
    _create_debug_overlay()
    
    # Connect signals
    for enemy in enemies:
        if enemy.has_signal("health_changed"):
            enemy.connect("health_changed", Callable(self, "_on_enemy_health_changed").bind(enemy))
    
    # Find cameras
    overview_camera = get_tree().get_first_node_in_group("overview_camera")
    if not overview_camera:
        overview_camera = get_node("/root/EnemyTestLevel/OverviewCamera")
    
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player_camera = player.get_node_or_null("Camera3D")
        
        # Connect player health signal
        if player.has_signal("health_changed"):
            player.connect("health_changed", Callable(self, "_on_player_health_changed"))
    
    # Set initial camera
    _switch_camera("player")
    
    # Make sure debug overlay is initially hidden
    debug_enabled = false
    if debug_overlay:
        debug_overlay.visible = debug_enabled

# Process input for debug controls
func _input(event):
    if event is InputEventKey:
        if event.pressed:
            match event.keycode:
                KEY_F1:
                    # Toggle debug overlay
                    debug_enabled = !debug_enabled
                    if debug_overlay:
                        debug_overlay.visible = debug_enabled
                
                KEY_F2:
                    # Damage all enemies (for testing)
                    for enemy in enemies:
                        if enemy.has_method("take_damage"):
                            enemy.take_damage(20.0, null)
                
                KEY_F3:
                    # Force mini-boss phase transition
                    if mini_boss and mini_boss.has_method("_transition_to_phase_two"):
                        mini_boss._transition_to_phase_two()
                
                KEY_TAB:
                    # Switch camera view
                    if current_camera == "player":
                        _switch_camera("overview")
                    else:
                        _switch_camera("player")

# Find all enemies in the scene
func _find_enemies():
    # Find standard enemies
    var standard_enemies = get_tree().get_nodes_in_group("enemies")
    if standard_enemies.size() == 0:
        # If no group is set, try finding by class
        for node in get_tree().get_nodes_in_group(""):
            if node is StandardEnemy or node.get_class() == "StandardEnemy":
                standard_enemies.append(node)
    
    # Find mini-boss
    var mini_bosses = get_tree().get_nodes_in_group("mini_bosses")
    if mini_bosses.size() == 0:
        # If no group is set, try finding by class
        for node in get_tree().get_nodes_in_group(""):
            if node is MiniBoss or node.get_class() == "MiniBoss":
                mini_bosses.append(node)
    
    # Add all to enemies array
    enemies.append_array(standard_enemies)
    enemies.append_array(mini_bosses)
    
    # Set mini-boss reference
    if mini_bosses.size() > 0:
        mini_boss = mini_bosses[0]
    
    # Add to groups if not already
    for enemy in enemies:
        if enemy is StandardEnemy and not enemy.is_in_group("enemies"):
            enemy.add_to_group("enemies")
        elif enemy is MiniBoss and not enemy.is_in_group("mini_bosses"):
            enemy.add_to_group("mini_bosses")

# Create debug overlay
func _create_debug_overlay():
    debug_overlay = Control.new()
    debug_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    debug_overlay.visible = debug_enabled
    add_child(debug_overlay)
    
    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
    vbox.position = Vector2(20, 20)
    vbox.size = Vector2(300, 500)
    debug_overlay.add_child(vbox)
    
    var title = Label.new()
    title.text = "Enemy Debug Info"
    title.add_theme_color_override("font_color", Color(1, 1, 0))
    vbox.add_child(title)
    
    # Add labels for each enemy
    for enemy in enemies:
        var label = Label.new()
        label.name = "Label_" + str(enemy.get_instance_id())
        label.text = _get_enemy_debug_info(enemy)
        label.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
        vbox.add_child(label)
    
    # Start updating debug info
    var timer = Timer.new()
    timer.wait_time = 0.5
    timer.autostart = true
    timer.connect("timeout", Callable(self, "_update_debug_info"))
    add_child(timer)

# Update debug info
func _update_debug_info():
    if not debug_enabled or not debug_overlay:
        return
    
    for enemy in enemies:
        var label = debug_overlay.find_child("Label_" + str(enemy.get_instance_id()), true, false)
        if label:
            label.text = _get_enemy_debug_info(enemy)

# Get debug info for an enemy
func _get_enemy_debug_info(enemy) -> String:
    var info = ""
    
    # Basic info
    info += enemy.name + " (" + enemy.get_class() + ")\n"
    
    # Health
    if enemy.has_method("get_health"):
        info += "Health: " + str(enemy.get_health()) + "/" + str(enemy.get_max_health()) + "\n"
    else:
        info += "Health: " + str(enemy.current_health) + "/" + str(enemy.base_health) + "\n"
    
    # State
    info += "State: " + str(enemy.current_state) + "\n"
    
    # Mini-boss specific
    if enemy is MiniBoss:
        info += "Phase: " + str(enemy.current_phase) + "\n"
        info += "Special Attack Timer: " + str(snappedf(enemy.special_attack_timer, 0.1)) + "\n"
        info += "Dash Timer: " + str(snappedf(enemy.dash_timer, 0.1)) + "\n"
    
    # Standard enemy specific
    if enemy is StandardEnemy:
        info += "Is Blocking: " + str(enemy.is_blocking) + "\n"
        if enemy.has_ranged_attack:
            info += "Can Use Ranged: " + str(enemy.can_use_ranged_attack) + "\n"
    
    return info

# Handle enemy health changed
func _on_enemy_health_changed(health, max_health, enemy):
    # Update debug info immediately
    if debug_enabled and debug_overlay:
        var label = debug_overlay.find_child("Label_" + str(enemy.get_instance_id()), true, false)
        if label:
            label.text = _get_enemy_debug_info(enemy)

# Force enemy to perform specific actions (for testing)
func force_enemy_action(enemy_type: String, action: String):
    var target_enemy = null
    
    # Find the target enemy
    if enemy_type == "StandardEnemy":
        for enemy in enemies:
            if enemy is StandardEnemy:
                target_enemy = enemy
                break
    elif enemy_type == "MiniBoss":
        target_enemy = mini_boss
    
    if not target_enemy:
        print("Enemy not found: ", enemy_type)
        return
    
    # Perform the action
    match action:
        "attack":
            if target_enemy.has_method("_perform_attack"):
                target_enemy._perform_attack()
        
        "block":
            if target_enemy is StandardEnemy and target_enemy.has_method("_block"):
                target_enemy._block()
        
        "dodge":
            if target_enemy is StandardEnemy and target_enemy.has_method("_dodge"):
                target_enemy._dodge()
        
        "ranged_attack":
            if target_enemy is StandardEnemy and target_enemy.has_method("_perform_ranged_attack"):
                target_enemy._perform_ranged_attack()
        
        "special_attack":
            if target_enemy is MiniBoss and target_enemy.has_method("_perform_special_attack"):
                target_enemy._perform_special_attack()
        
        "dash_attack":
            if target_enemy is MiniBoss and target_enemy.has_method("_perform_dash_attack"):
                target_enemy._perform_dash_attack()

# Switch between camera views
func _switch_camera(camera_name: String):
    if camera_name == "player" and player_camera:
        player_camera.current = true
        if overview_camera:
            overview_camera.current = false
        current_camera = "player"
    elif camera_name == "overview" and overview_camera:
        overview_camera.current = true
        if player_camera:
            player_camera.current = false
        current_camera = "overview"

# Handle player health changed
func _on_player_health_changed(health, max_health):
    # Update player health bar
    var player = get_tree().get_first_node_in_group("player")
    if player:
        var health_bar = player.get_node_or_null("HUD/HealthBar")
        if health_bar:
            health_bar.value = (health / max_health) * 100.0 