extends Node
class_name CheckpointSystem

"""
CheckpointSystem: Manages checkpoints (bonfires) and player respawning.
Handles checkpoint activation, respawn logic, and enemy reset.
"""

# Signal declarations
signal checkpoint_activated(checkpoint_id: String)
signal player_respawned(checkpoint_id: String)

# Checkpoint data
var checkpoints: Dictionary = {}
var active_checkpoint: String = ""
var discovered_checkpoints: Array[String] = []

# References
var player: PlayerCharacter = null
var enemy_manager = null

func _ready() -> void:
	"""Initialize the checkpoint system."""
	# Find all checkpoints in the scene
	_find_checkpoints()

func register_player(player_character: PlayerCharacter) -> void:
	"""Register the player character with the checkpoint system."""
	player = player_character
	player.connect("player_died", Callable(self, "_on_player_died"))

func register_enemy_manager(manager) -> void:
	"""Register the enemy manager for respawning enemies."""
	enemy_manager = manager

func _find_checkpoints() -> void:
	"""Find all checkpoints in the scene and register them."""
	var checkpoint_nodes = get_tree().get_nodes_in_group("checkpoint")
	
	for checkpoint in checkpoint_nodes:
		if checkpoint.has_method("get_checkpoint_id"):
			var id = checkpoint.get_checkpoint_id()
			checkpoints[id] = checkpoint
			checkpoint.connect("checkpoint_reached", Callable(self, "_on_checkpoint_reached"))

func register_checkpoint(checkpoint_node) -> void:
	"""Register a checkpoint manually."""
	if checkpoint_node.has_method("get_checkpoint_id"):
		var id = checkpoint_node.get_checkpoint_id()
		checkpoints[id] = checkpoint_node
		checkpoint_node.connect("checkpoint_reached", Callable(self, "_on_checkpoint_reached"))

func _on_checkpoint_reached(checkpoint_id: String) -> void:
	"""Handle player reaching a checkpoint."""
	# Set as active checkpoint
	active_checkpoint = checkpoint_id
	
	# Add to discovered checkpoints if not already there
	if not discovered_checkpoints.has(checkpoint_id):
		discovered_checkpoints.append(checkpoint_id)
	
	# Emit signal
	emit_signal("checkpoint_activated", checkpoint_id)
	
	# Heal player
	if player:
		player.heal(player.get_max_health())
		player.current_stamina = player.get_max_stamina()
	
	# Respawn enemies
	_respawn_enemies()

func _on_player_died() -> void:
	"""Handle player death."""
	if active_checkpoint != "":
		# Schedule respawn after a delay
		await get_tree().create_timer(3.0).timeout
		respawn_player()

func respawn_player() -> void:
	"""Respawn the player at the active checkpoint."""
	if not player or active_checkpoint == "":
		return
	
	# Get checkpoint node
	var checkpoint = checkpoints.get(active_checkpoint)
	if not checkpoint:
		return
	
	# Get respawn position
	var respawn_position = checkpoint.get_respawn_position()
	
	# Reset player
	player.global_position = respawn_position
	player.current_health = player.get_max_health()
	player.current_stamina = player.get_max_stamina()
	
	# Reset player state
	player.current_state = player.PlayerState.IDLE
	player.is_invulnerable = true
	
	# Play respawn animation
	player.animation_player.play("respawn")
	await player.animation_player.animation_finished
	
	player.is_invulnerable = false
	
	# Emit signal
	emit_signal("player_respawned", active_checkpoint)

func _respawn_enemies() -> void:
	"""Respawn all enemies in the world."""
	if enemy_manager:
		enemy_manager.respawn_all_enemies()

func can_fast_travel() -> bool:
	"""Check if fast travel is currently available."""
	# In Soulsborne games, fast travel is often restricted in certain situations
	if not player:
		return false
	
	# Can't fast travel during combat or when dead
	if player.current_state == player.PlayerState.ATTACKING or \
	   player.current_state == player.PlayerState.BLOCKING or \
	   player.current_state == player.PlayerState.DEAD:
		return false
	
	return true

func fast_travel(destination_id: String) -> bool:
	"""Fast travel to a discovered checkpoint."""
	# Check if fast travel is available
	if not can_fast_travel():
		return false
	
	# Check if destination is discovered
	if not discovered_checkpoints.has(destination_id):
		return false
	
	# Get destination checkpoint
	var destination = checkpoints.get(destination_id)
	if not destination:
		return false
	
	# Set as active checkpoint
	active_checkpoint = destination_id
	
	# Get respawn position
	var respawn_position = destination.get_respawn_position()
	
	# Play fast travel animation
	player.animation_player.play("fast_travel_out")
	await player.animation_player.animation_finished
	
	# Move player
	player.global_position = respawn_position
	
	# Play arrival animation
	player.animation_player.play("fast_travel_in")
	await player.animation_player.animation_finished
	
	# Respawn enemies
	_respawn_enemies()
	
	return true

func get_discovered_checkpoints() -> Array[String]:
	"""Get a list of discovered checkpoint IDs."""
	return discovered_checkpoints

func get_checkpoint_name(checkpoint_id: String) -> String:
	"""Get the display name of a checkpoint."""
	var checkpoint = checkpoints.get(checkpoint_id)
	if checkpoint and checkpoint.has_method("get_display_name"):
		return checkpoint.get_display_name()
	return "Unknown Checkpoint"

func get_checkpoint_position(checkpoint_id: String) -> Vector3:
	"""Get the position of a checkpoint."""
	var checkpoint = checkpoints.get(checkpoint_id)
	if checkpoint:
		return checkpoint.global_position
	return Vector3.ZERO 