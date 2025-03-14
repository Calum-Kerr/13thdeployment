extends Node

# Web export main script
# This is a simplified version for web browsers

var player_scene = preload("res://src/debug/test_player.tscn")
var standard_enemy_scene = preload("res://src/enemies/standard_enemy.tscn")

var player = null
var enemy = null

func _ready():
	# Print welcome message
	print("Soulsborne Web Game - Web Export Version")
	
	# Create simple environment
	_create_environment()
	
	# Spawn player
	_spawn_player()
	
	# Spawn enemy
	_spawn_enemy()

func _create_environment():
	# Create a simple ground
	var ground = CSGBox3D.new()
	ground.size = Vector3(20, 1, 20)
	ground.position = Vector3(0, -0.5, 0)
	
	# Create a simple material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	ground.material = material
	
	add_child(ground)
	
	# Create a light
	var light = DirectionalLight3D.new()
	light.transform.basis = Basis(Vector3(0.5, -0.5, 0.5).normalized(), PI * 0.25)
	light.transform.origin = Vector3(0, 10, 0)
	light.shadow_enabled = true
	add_child(light)
	
	# Create instructions
	var instructions = Label3D.new()
	instructions.text = "Soulsborne Web Game Demo\n\nControls:\n- WASD or Arrow Keys to move\n- Space to attack"
	instructions.position = Vector3(0, 3, 0)
	instructions.font_size = 48
	instructions.outline_size = 12
	add_child(instructions)

func _spawn_player():
	# Create player instance
	player = player_scene.instantiate()
	add_child(player)
	
	# Position player
	player.global_position = Vector3(0, 0.5, 5)
	
	# Add to player group
	player.add_to_group("player")
	
	# Create camera
	var camera = Camera3D.new()
	camera.transform.origin = Vector3(0, 5, 10)
	camera.transform.basis = Basis(Vector3(1, 0, 0), -0.5)
	camera.current = true
	add_child(camera)

func _spawn_enemy():
	# Create enemy instance
	enemy = standard_enemy_scene.instantiate()
	add_child(enemy)
	
	# Position enemy
	enemy.global_position = Vector3(0, 0.5, -5)
	
	# Set player reference
	if enemy.has_method("set_player"):
		enemy.set_player(player)
	elif enemy.has_method("_find_player"):
		enemy._find_player()

func _process(delta):
	# Check for escape key to quit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	# Update enemy state if needed
	if enemy and enemy.current_state == enemy.EnemyState.IDLE:
		enemy._change_state(enemy.EnemyState.CHASE) 