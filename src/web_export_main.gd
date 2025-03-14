extends Node

# Simple web export main script
# This is a simplified version of the game for web export

var player_scene = preload("res://src/debug/test_player.tscn")
var standard_enemy_scene = preload("res://src/enemies/standard_enemy.tscn")
var mini_boss_scene = preload("res://src/enemies/mini_boss.tscn")

var player = null
var enemies = []

func _ready():
	# Print welcome message
	print("Soulsborne Web Game Demo - Web Export Version")
	
	# Spawn player
	_spawn_player()
	
	# Spawn enemies
	_spawn_enemies()
	
	# Add to groups for easy access
	add_to_group("current_level")

func _spawn_player():
	# Create player instance
	player = player_scene.instantiate()
	add_child(player)
	
	# Position at spawn point
	var spawn_point = $PlayerSpawnPoint
	player.global_position = spawn_point.global_position
	
	# Add to player group
	player.add_to_group("player")

func _spawn_enemies():
	# Spawn standard enemy
	var enemy = standard_enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = $EnemySpawnPoint.global_position + Vector3(2, 0, 0)
	enemies.append(enemy)
	
	# Spawn mini-boss
	var boss = mini_boss_scene.instantiate()
	add_child(boss)
	boss.global_position = $EnemySpawnPoint.global_position + Vector3(-2, 0, 0)
	enemies.append(boss)
	
	# Set player reference for enemies
	for e in enemies:
		if e.has_method("set_player"):
			e.set_player(player)
		elif e.has_method("_find_player"):
			e._find_player()

func _process(delta):
	# Check for escape key to quit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	# Update enemy states if needed
	for enemy in enemies:
		if enemy.current_state == enemy.EnemyState.IDLE:
			enemy._change_state(enemy.EnemyState.CHASE) 