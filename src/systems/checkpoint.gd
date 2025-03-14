extends Node3D
class_name Checkpoint

"""
Checkpoint: Represents a bonfire/checkpoint in the game.
Players can rest here to heal, respawn, and reset enemies.
"""

# Signal declarations
signal checkpoint_reached(checkpoint_id: String)
signal checkpoint_activated(checkpoint_id: String)
signal checkpoint_menu_opened()
signal checkpoint_menu_closed()

# Checkpoint properties
@export var checkpoint_id: String = "checkpoint_01"
@export var display_name: String = "Unnamed Checkpoint"
@export var is_unlocked: bool = true
@export var unlock_item: String = ""
@export var is_warpable: bool = true

# Visual components
@export var fire_particles: NodePath
@export var light: NodePath
@export var interaction_area: NodePath

# State
var is_active: bool = false
var is_discovered: bool = false
var menu_open: bool = false

# References
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_prompt: Node3D = $InteractionPrompt

func _ready() -> void:
	"""Initialize the checkpoint."""
	# Set up interaction area
	var area = get_node_or_null(interaction_area)
	if area:
		area.connect("body_entered", Callable(self, "_on_interaction_area_body_entered"))
		area.connect("body_exited", Callable(self, "_on_interaction_area_body_exited"))
	
	# Hide interaction prompt initially
	if interaction_prompt:
		interaction_prompt.visible = false
	
	# Set initial visual state
	_update_visual_state()

func _process(delta: float) -> void:
	"""Process checkpoint logic."""
	# Check for interaction input when player is in range
	if interaction_prompt and interaction_prompt.visible and Input.is_action_just_pressed("interact"):
		_interact()

func _update_visual_state() -> void:
	"""Update the visual state of the checkpoint based on its status."""
	var particles = get_node_or_null(fire_particles)
	var light_node = get_node_or_null(light)
	
	if particles:
		if is_active:
			# Full fire for active checkpoint
			particles.emitting = true
			particles.amount = 100
		elif is_discovered:
			# Smaller fire for discovered but inactive checkpoint
			particles.emitting = true
			particles.amount = 50
		else:
			# No fire for undiscovered checkpoint
			particles.emitting = false
	
	if light_node:
		if is_active:
			# Bright light for active checkpoint
			light_node.light_energy = 1.0
		elif is_discovered:
			# Dim light for discovered but inactive checkpoint
			light_node.light_energy = 0.5
		else:
			# No light for undiscovered checkpoint
			light_node.light_energy = 0.0
	
	# Play appropriate animation
	if animation_player:
		if is_active:
			animation_player.play("active")
		elif is_discovered:
			animation_player.play("discovered")
		else:
			animation_player.play("undiscovered")

func activate() -> void:
	"""Activate the checkpoint."""
	is_discovered = true
	is_active = true
	_update_visual_state()
	emit_signal("checkpoint_activated", checkpoint_id)

func discover() -> void:
	"""Mark the checkpoint as discovered."""
	is_discovered = true
	_update_visual_state()

func _interact() -> void:
	"""Handle player interaction with the checkpoint."""
	if not is_unlocked:
		# Check if player has the unlock item
		var game_manager = get_node("/root/GameManager")
		if game_manager and game_manager.has_method("has_item"):
			if game_manager.has_item(unlock_item):
				is_unlocked = true
				game_manager.remove_item(unlock_item)
			else:
				# Show "locked" message
				if game_manager.has_method("show_notification"):
					game_manager.show_notification("This checkpoint is locked. Find the " + unlock_item + " to unlock it.")
				return
	
	# Emit signal that checkpoint was reached
	emit_signal("checkpoint_reached", checkpoint_id)
	
	# Open checkpoint menu
	_open_menu()

func _open_menu() -> void:
	"""Open the checkpoint menu."""
	if menu_open:
		return
	
	menu_open = true
	emit_signal("checkpoint_menu_opened")
	
	# This would typically be handled by the UI system
	var game_manager = get_node("/root/GameManager")
	if game_manager and game_manager.has_method("open_checkpoint_menu"):
		game_manager.open_checkpoint_menu(self)

func close_menu() -> void:
	"""Close the checkpoint menu."""
	if not menu_open:
		return
	
	menu_open = false
	emit_signal("checkpoint_menu_closed")

func get_checkpoint_id() -> String:
	"""Get the unique ID of this checkpoint."""
	return checkpoint_id

func get_display_name() -> String:
	"""Get the display name of this checkpoint."""
	return display_name

func get_respawn_position() -> Vector3:
	"""Get the position where the player should respawn."""
	# Use a dedicated respawn position node if available
	var respawn_pos = get_node_or_null("RespawnPosition")
	if respawn_pos:
		return respawn_pos.global_position
	
	# Otherwise use the checkpoint's position with a small offset
	return global_position + Vector3(0, 0.1, 0)

func can_warp_to() -> bool:
	"""Check if this checkpoint can be warped to."""
	return is_warpable and is_discovered

func _on_interaction_area_body_entered(body: Node3D) -> void:
	"""Handle body entering the interaction area."""
	if body is PlayerCharacter:
		if interaction_prompt:
			interaction_prompt.visible = true

func _on_interaction_area_body_exited(body: Node3D) -> void:
	"""Handle body exiting the interaction area."""
	if body is PlayerCharacter:
		if interaction_prompt:
			interaction_prompt.visible = false
		
		# Close menu if open
		if menu_open:
			close_menu() 