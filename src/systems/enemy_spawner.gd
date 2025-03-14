extends Node
class_name EnemySpawner

# Signals
signal enemy_spawned(enemy, spawn_point)
signal all_enemies_spawned
signal all_enemies_defeated

# Spawn point class
class SpawnPoint:
    var position: Vector3
    var enemy_type: String
    var respawn_time: float
    var is_active: bool = true
    var timer: float = 0.0
    var enemy_instance = null
    var unique_id: String = ""
    var is_boss: bool = false
    
    func _init(pos: Vector3, type: String, resp_time: float = 30.0, id: String = "", boss: bool = false):
        position = pos
        enemy_type = type
        respawn_time = resp_time
        unique_id = id
        is_boss = boss

# Enemy types and their scene paths
var enemy_scenes = {
    "standard": "res://src/enemies/standard_enemy.tscn",
    "mini_boss": "res://src/enemies/mini_boss.tscn",
    # Add more enemy types as needed
}

# Spawn points array
var spawn_points: Array[SpawnPoint] = []

# Configuration
@export var auto_spawn: bool = true
@export var respawn_enemies: bool = true
@export var player_distance_spawn: float = 50.0
@export var player_distance_despawn: float = 70.0
@export var max_concurrent_enemies: int = 20
@export var initial_spawn_delay: float = 2.0

# Runtime variables
var active_enemies: int = 0
var player_ref: PlayerCharacter = null
var game_manager_ref = null
var initial_spawn_complete: bool = false
var defeated_bosses: Array[String] = []

# Called when the node enters the scene tree for the first time
func _ready():
    # Wait for game manager to be ready
    await get_tree().create_timer(0.5).timeout
    
    # Get references
    game_manager_ref = get_node("/root/GameManager")
    if game_manager_ref:
        game_manager_ref.connect("player_ready", _on_player_ready)
        game_manager_ref.connect("game_reset", _on_game_reset)
    
    # Initial delay before spawning
    if auto_spawn:
        await get_tree().create_timer(initial_spawn_delay).timeout
        _initial_spawn()

# Process function to handle respawning
func _process(delta):
    if not player_ref or not respawn_enemies:
        return
    
    var player_pos = player_ref.global_position
    
    # Update spawn timers and handle respawning
    for spawn_point in spawn_points:
        # Skip if this is a defeated boss
        if spawn_point.is_boss and defeated_bosses.has(spawn_point.unique_id):
            continue
            
        # If enemy is dead and timer is running
        if spawn_point.enemy_instance == null or not is_instance_valid(spawn_point.enemy_instance):
            if spawn_point.is_active:
                spawn_point.timer += delta
                
                # Time to respawn
                if spawn_point.timer >= spawn_point.respawn_time:
                    # Check player distance for respawning
                    var distance = player_pos.distance_to(spawn_point.position)
                    
                    # Only spawn if player is far enough away or not in the same area
                    if distance > player_distance_spawn / 2.0 and distance < player_distance_spawn:
                        if active_enemies < max_concurrent_enemies:
                            _spawn_enemy(spawn_point)
                            spawn_point.timer = 0.0
        else:
            # Check if enemy should be despawned due to distance
            var distance = player_pos.distance_to(spawn_point.position)
            if distance > player_distance_despawn:
                # Only despawn non-boss enemies that are far away
                if not spawn_point.is_boss:
                    spawn_point.enemy_instance.queue_free()
                    spawn_point.enemy_instance = null
                    active_enemies -= 1

# Add a spawn point
func add_spawn_point(position: Vector3, enemy_type: String, respawn_time: float = 30.0, unique_id: String = "", is_boss: bool = false):
    var spawn_point = SpawnPoint.new(position, enemy_type, respawn_time, unique_id, is_boss)
    spawn_points.append(spawn_point)
    return spawn_point

# Remove a spawn point
func remove_spawn_point(spawn_point):
    if spawn_point.enemy_instance and is_instance_valid(spawn_point.enemy_instance):
        spawn_point.enemy_instance.queue_free()
        active_enemies -= 1
    
    spawn_points.erase(spawn_point)

# Initial spawn of all enemies
func _initial_spawn():
    for spawn_point in spawn_points:
        # Skip if this is a defeated boss
        if spawn_point.is_boss and defeated_bosses.has(spawn_point.unique_id):
            continue
            
        if spawn_point.is_active and active_enemies < max_concurrent_enemies:
            _spawn_enemy(spawn_point)
            # Small delay between spawns to prevent performance spikes
            await get_tree().create_timer(0.1).timeout
    
    initial_spawn_complete = true
    emit_signal("all_enemies_spawned")

# Spawn a single enemy at a spawn point
func _spawn_enemy(spawn_point):
    if not enemy_scenes.has(spawn_point.enemy_type):
        push_error("Enemy type not found: " + spawn_point.enemy_type)
        return
    
    var enemy_scene = load(enemy_scenes[spawn_point.enemy_type])
    if enemy_scene:
        var enemy = enemy_scene.instantiate()
        get_tree().current_scene.add_child(enemy)
        enemy.global_position = spawn_point.position
        
        # Connect signals
        if enemy.has_signal("enemy_killed"):
            enemy.connect("enemy_killed", _on_enemy_killed.bind(spawn_point))
        
        # Store reference
        spawn_point.enemy_instance = enemy
        active_enemies += 1
        
        # Emit signal
        emit_signal("enemy_spawned", enemy, spawn_point)
        
        return enemy
    
    return null

# Handle player ready event
func _on_player_ready(player):
    player_ref = player
    
    # Initial spawn if not already done
    if auto_spawn and not initial_spawn_complete:
        _initial_spawn()

# Handle enemy killed event
func _on_enemy_killed(souls, spawn_point):
    active_enemies -= 1
    
    # If this was a boss, mark it as defeated
    if spawn_point.is_boss and spawn_point.unique_id != "":
        defeated_bosses.append(spawn_point.unique_id)
        
        # Save defeated boss to game state
        if game_manager_ref and game_manager_ref.has_method("register_defeated_boss"):
            game_manager_ref.register_defeated_boss(spawn_point.unique_id)
    
    # Reset the spawn timer
    spawn_point.enemy_instance = null
    spawn_point.timer = 0.0
    
    # Check if all enemies are defeated
    var all_defeated = true
    for point in spawn_points:
        if point.is_active and (point.enemy_instance != null and is_instance_valid(point.enemy_instance)):
            all_defeated = false
            break
    
    if all_defeated and initial_spawn_complete:
        emit_signal("all_enemies_defeated")

# Handle game reset
func _on_game_reset():
    # Clear all existing enemies
    for spawn_point in spawn_points:
        if spawn_point.enemy_instance and is_instance_valid(spawn_point.enemy_instance):
            spawn_point.enemy_instance.queue_free()
            spawn_point.enemy_instance = null
    
    active_enemies = 0
    initial_spawn_complete = false
    
    # Reset defeated bosses based on game state
    if game_manager_ref and game_manager_ref.has_method("get_defeated_bosses"):
        defeated_bosses = game_manager_ref.get_defeated_bosses()
    else:
        defeated_bosses.clear()
    
    # Restart spawning
    if auto_spawn:
        await get_tree().create_timer(initial_spawn_delay).timeout
        _initial_spawn()

# Manually spawn all enemies
func spawn_all_enemies():
    _initial_spawn()

# Manually despawn all enemies
func despawn_all_enemies():
    for spawn_point in spawn_points:
        if spawn_point.enemy_instance and is_instance_valid(spawn_point.enemy_instance):
            spawn_point.enemy_instance.queue_free()
            spawn_point.enemy_instance = null
    
    active_enemies = 0
    initial_spawn_complete = false 