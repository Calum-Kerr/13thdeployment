extends Node
class_name LevelManager

# References
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D

# Level properties
@export var level_id: String = "level_1"
@export var level_name: String = "Undead Ruins"
@export var level_difficulty: int = 1
@export var boss_id: String = ""

# Spawn configuration
@export var standard_enemy_count: int = 10
@export var mini_boss_count: int = 1
@export var standard_enemy_respawn_time: float = 30.0
@export var mini_boss_respawn_time: float = 120.0

# Level state
var level_completed: bool = false
var player_entered: bool = false
var spawn_points: Array = []
var boss_defeated: bool = false

# References
var game_manager = null
var player_ref: PlayerCharacter = null

# Called when the node enters the scene tree for the first time
func _ready():
    # Wait for game manager to be ready
    await get_tree().create_timer(0.5).timeout
    
    # Get references
    game_manager = get_node_or_null("/root/GameManager")
    if game_manager:
        if game_manager.has_signal("player_ready"):
            game_manager.connect("player_ready", _on_player_ready)
        if game_manager.has_signal("game_reset"):
            game_manager.connect("game_reset", _on_game_reset)
    
    # Connect enemy spawner signals
    if enemy_spawner:
        if enemy_spawner.has_signal("all_enemies_defeated"):
            enemy_spawner.connect("all_enemies_defeated", _on_all_enemies_defeated)
    
    # Setup level
    _setup_level()
    
    # For test level, manually find player and activate enemies
    if get_tree().get_nodes_in_group("player").size() > 0:
        player_ref = get_tree().get_nodes_in_group("player")[0]
        _activate_enemies_for_testing()

# Activate enemies for testing
func _activate_enemies_for_testing():
    # Find all enemies in the scene
    var enemies = get_tree().get_nodes_in_group("enemies")
    enemies.append_array(get_tree().get_nodes_in_group("mini_bosses"))
    
    # Activate each enemy
    for enemy in enemies:
        if enemy.has_method("set_player"):
            enemy.set_player(player_ref)
        
        # Make sure enemies are in IDLE state initially
        if enemy.has_method("_change_state") and enemy.has_property("STATE"):
            enemy._change_state(enemy.STATE.IDLE)
    
    # If we have an enemy spawner, activate it
    if enemy_spawner:
        enemy_spawner.player_ref = player_ref
        
        # Manually register spawn points for existing enemies
        for enemy in enemies:
            var spawn_point = enemy_spawner.add_spawn_point(
                enemy.global_position,
                "standard" if enemy.is_in_group("enemies") else "mini_boss",
                standard_enemy_respawn_time if enemy.is_in_group("enemies") else mini_boss_respawn_time,
                "",
                enemy.is_in_group("mini_bosses")
            )
            spawn_point.enemy_instance = enemy
            enemy_spawner.active_enemies += 1

# Setup the level with spawn points
func _setup_level():
    # Clear existing spawn points
    spawn_points.clear()
    
    # Get all spawn point markers in the level
    var spawn_markers = get_tree().get_nodes_in_group("enemy_spawn_point")
    
    if spawn_markers.size() > 0:
        # Use predefined spawn points
        for marker in spawn_markers:
            var enemy_type = "standard"
            var respawn_time = standard_enemy_respawn_time
            var is_boss = false
            var unique_id = ""
            
            # Check marker properties if available
            if marker.has_meta("enemy_type"):
                enemy_type = marker.get_meta("enemy_type")
            
            if marker.has_meta("respawn_time"):
                respawn_time = marker.get_meta("respawn_time")
            
            if marker.has_meta("is_boss"):
                is_boss = marker.get_meta("is_boss")
            
            if marker.has_meta("unique_id"):
                unique_id = marker.get_meta("unique_id")
            elif is_boss and boss_id != "":
                unique_id = boss_id
            
            # Add spawn point
            var spawn_point = enemy_spawner.add_spawn_point(
                marker.global_position,
                enemy_type,
                respawn_time,
                unique_id,
                is_boss
            )
            
            spawn_points.append(spawn_point)
    else:
        # Generate random spawn points
        _generate_random_spawn_points()

# Generate random spawn points within the navigation mesh
func _generate_random_spawn_points():
    if not navigation_region:
        push_error("No NavigationRegion3D found in level")
        return
    
    var nav_mesh = navigation_region.navigation_mesh
    if not nav_mesh:
        push_error("No navigation mesh found in NavigationRegion3D")
        return
    
    # Get navigation mesh bounds
    var bounds_min = Vector3(999999, 999999, 999999)
    var bounds_max = Vector3(-999999, -999999, -999999)
    
    # This is a simplified approach - in a real game you'd use the actual vertices
    # of the navigation mesh to determine bounds
    bounds_min = Vector3(-50, 0, -50)
    bounds_max = Vector3(50, 5, 50)
    
    # Spawn standard enemies
    for i in range(standard_enemy_count):
        var position = _get_random_position_in_bounds(bounds_min, bounds_max)
        var spawn_point = enemy_spawner.add_spawn_point(
            position,
            "standard",
            standard_enemy_respawn_time
        )
        spawn_points.append(spawn_point)
    
    # Spawn mini-bosses
    for i in range(mini_boss_count):
        var position = _get_random_position_in_bounds(bounds_min, bounds_max)
        var unique_id = ""
        if i == 0 and boss_id != "":
            unique_id = boss_id
        
        var spawn_point = enemy_spawner.add_spawn_point(
            position,
            "mini_boss",
            mini_boss_respawn_time,
            unique_id,
            true
        )
        spawn_points.append(spawn_point)

# Get a random position within bounds that's on the navigation mesh
func _get_random_position_in_bounds(bounds_min: Vector3, bounds_max: Vector3) -> Vector3:
    var position = Vector3.ZERO
    var valid_position = false
    var attempts = 0
    
    while not valid_position and attempts < 50:
        # Generate random position
        position.x = randf_range(bounds_min.x, bounds_max.x)
        position.y = randf_range(bounds_min.y, bounds_max.y)
        position.z = randf_range(bounds_min.z, bounds_max.z)
        
        # Check if position is on navigation mesh
        if navigation_region:
            var closest_point = navigation_region.get_closest_point(position)
            if position.distance_to(closest_point) < 1.0:
                position = closest_point
                valid_position = true
        
        attempts += 1
    
    if not valid_position:
        # Fallback to center of bounds
        position = (bounds_min + bounds_max) / 2.0
        position.y = bounds_min.y  # Keep on ground
    
    return position

# Handle player entering the level
func _on_player_ready(player):
    player_ref = player
    player_entered = true
    
    # Check if boss is already defeated
    if game_manager and game_manager.has_method("is_boss_defeated") and boss_id != "":
        boss_defeated = game_manager.is_boss_defeated(boss_id)
    
    # Update level state
    _update_level_state()

# Handle all enemies defeated
func _on_all_enemies_defeated():
    # Check if this completes the level
    if boss_id != "" and not boss_defeated:
        # Check if boss is now defeated
        if game_manager and game_manager.has_method("is_boss_defeated"):
            boss_defeated = game_manager.is_boss_defeated(boss_id)
            
            if boss_defeated:
                _complete_level()
    else:
        # No boss in this level, so it's completed when all enemies are defeated
        _complete_level()

# Complete the level
func _complete_level():
    if not level_completed:
        level_completed = true
        
        # Notify game manager
        if game_manager and game_manager.has_method("level_completed"):
            game_manager.level_completed(level_id)
        
        # Trigger any level completion events
        _trigger_level_completion_events()

# Trigger level completion events
func _trigger_level_completion_events():
    # This could unlock doors, spawn rewards, etc.
    pass

# Update level state based on game progress
func _update_level_state():
    # Check if level is already completed
    if game_manager and game_manager.has_method("is_level_completed"):
        level_completed = game_manager.is_level_completed(level_id)
    
    # Update boss state
    if boss_id != "" and game_manager and game_manager.has_method("is_boss_defeated"):
        boss_defeated = game_manager.is_boss_defeated(boss_id)

# Handle game reset
func _on_game_reset():
    player_entered = false
    level_completed = false
    boss_defeated = false
    
    # Update level state
    _update_level_state()

# Manually activate the level
func activate_level():
    if enemy_spawner:
        enemy_spawner.spawn_all_enemies()

# Manually deactivate the level
func deactivate_level():
    if enemy_spawner:
        enemy_spawner.despawn_all_enemies() 