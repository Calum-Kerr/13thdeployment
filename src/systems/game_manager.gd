extends Node

"""
GameManager: Central coordinator for all game systems.
Manages game state, progression, and coordinates between different systems.
"""

# Signal declarations
signal game_started()
signal game_paused(is_paused: bool)
signal area_changed(area_id: String, area_name: String)
signal player_leveled_up(new_level: int)
signal item_acquired(item_data: Dictionary)
signal quest_updated(quest_id: String, status: String)
signal achievement_unlocked(achievement_id: String)

# Game state
enum GameState {MAIN_MENU, LOADING, PLAYING, PAUSED, DIALOG, CUTSCENE, GAME_OVER}
var current_state: int = GameState.MAIN_MENU
var previous_state: int = GameState.MAIN_MENU

# Player data
var player_level: int = 1
var player_souls: int = 0
var player_stats: Dictionary = {}
var player_inventory: Array = []
var player_equipment: Dictionary = {}
var player_discovered_areas: Array = []
var player_unlocked_shortcuts: Array = []
var player_quests: Dictionary = {}
var player_achievements: Dictionary = {}

# Game progress
var current_area: String = ""
var current_area_name: String = ""
var game_difficulty: float = 1.0
var game_time: float = 0.0
var death_count: int = 0

# System references
var player: PlayerCharacter = null
var checkpoint_system: CheckpointSystem = null
var multiplayer_system: MultiplayerSystem = null
var enemy_manager = null
var ui_manager = null
var save_system = null
var sound_manager = null

# Web-specific
var is_web_build: bool = true
var local_storage_key: String = "soulsborne_web_save"

func _ready() -> void:
	"""Initialize the game manager."""
	# Set as singleton
	if Engine.has_singleton("GameManager"):
		push_error("Multiple GameManager instances detected!")
		queue_free()
		return
	
	# Initialize systems
	_initialize_systems()
	
	# Check for saved game
	if is_web_build:
		_check_web_save()
	
	# Connect signals
	_connect_signals()

func _process(delta: float) -> void:
	"""Process game logic."""
	# Update game time
	if current_state == GameState.PLAYING:
		game_time += delta
	
	# Handle input
	_handle_input()

func _initialize_systems() -> void:
	"""Initialize all game systems."""
	# Find or create required systems
	checkpoint_system = get_node_or_null("/root/CheckpointSystem")
	if not checkpoint_system:
		checkpoint_system = CheckpointSystem.new()
		checkpoint_system.name = "CheckpointSystem"
		get_tree().root.add_child(checkpoint_system)
	
	multiplayer_system = get_node_or_null("/root/MultiplayerSystem")
	if not multiplayer_system:
		multiplayer_system = MultiplayerSystem.new()
		multiplayer_system.name = "MultiplayerSystem"
		get_tree().root.add_child(multiplayer_system)
	
	# Initialize other managers (these would be implemented separately)
	enemy_manager = get_node_or_null("/root/EnemyManager")
	ui_manager = get_node_or_null("/root/UIManager")
	save_system = get_node_or_null("/root/SaveSystem")
	sound_manager = get_node_or_null("/root/SoundManager")

func _connect_signals() -> void:
	"""Connect signals between systems."""
	if checkpoint_system:
		checkpoint_system.connect("checkpoint_activated", Callable(self, "_on_checkpoint_activated"))
		checkpoint_system.connect("player_respawned", Callable(self, "_on_player_respawned"))
	
	if multiplayer_system:
		multiplayer_system.connect("player_invasion_started", Callable(self, "_on_player_invasion_started"))

func register_player(player_character: PlayerCharacter) -> void:
	"""Register the player character with the game manager."""
	player = player_character
	
	# Connect player signals
	player.connect("player_died", Callable(self, "_on_player_died"))
	player.connect("souls_changed", Callable(self, "_on_souls_changed"))
	
	# Register player with other systems
	if checkpoint_system:
		checkpoint_system.register_player(player)
	
	if multiplayer_system:
		multiplayer_system.register_player(player)
	
	# Initialize player stats
	_initialize_player_stats()

func start_game() -> void:
	"""Start a new game."""
	current_state = GameState.PLAYING
	
	# Reset player stats for new game
	_reset_player_for_new_game()
	
	# Load starting area
	change_area("tutorial_area", "Abandoned Crypt")
	
	emit_signal("game_started")

func load_game(save_data: Dictionary) -> bool:
	"""Load a saved game."""
	if not save_data.has("player_data") or not save_data.has("game_progress"):
		return false
	
	# Load player data
	var player_data = save_data.player_data
	player_level = player_data.get("level", 1)
	player_souls = player_data.get("souls", 0)
	player_stats = player_data.get("stats", {})
	player_inventory = player_data.get("inventory", [])
	player_equipment = player_data.get("equipment", {})
	
	# Load game progress
	var game_progress = save_data.game_progress
	current_area = game_progress.get("current_area", "tutorial_area")
	current_area_name = game_progress.get("current_area_name", "Abandoned Crypt")
	player_discovered_areas = game_progress.get("discovered_areas", [])
	player_unlocked_shortcuts = game_progress.get("unlocked_shortcuts", [])
	player_quests = game_progress.get("quests", {})
	player_achievements = game_progress.get("achievements", {})
	game_time = game_progress.get("game_time", 0.0)
	death_count = game_progress.get("death_count", 0)
	
	# Apply loaded data to player
	if player:
		_apply_player_stats()
	
	# Change to the saved area
	change_area(current_area, current_area_name)
	
	# Set game state
	current_state = GameState.PLAYING
	
	return true

func save_game() -> Dictionary:
	"""Save the current game state."""
	# Collect player data
	var player_data = {
		"level": player_level,
		"souls": player_souls,
		"stats": player_stats,
		"inventory": player_inventory,
		"equipment": player_equipment
	}
	
	# Collect game progress
	var game_progress = {
		"current_area": current_area,
		"current_area_name": current_area_name,
		"discovered_areas": player_discovered_areas,
		"unlocked_shortcuts": player_unlocked_shortcuts,
		"quests": player_quests,
		"achievements": player_achievements,
		"game_time": game_time,
		"death_count": death_count
	}
	
	# Create save data
	var save_data = {
		"player_data": player_data,
		"game_progress": game_progress,
		"save_timestamp": Time.get_unix_time_from_system(),
		"save_version": "1.0"
	}
	
	# Save to web storage if web build
	if is_web_build:
		_save_to_web_storage(save_data)
	
	return save_data

func change_area(area_id: String, area_name: String) -> void:
	"""Change to a different area."""
	# Set loading state
	var previous_area = current_area
	current_state = GameState.LOADING
	
	# Update area tracking
	current_area = area_id
	current_area_name = area_name
	
	if not player_discovered_areas.has(area_id):
		player_discovered_areas.append(area_id)
	
	# Update multiplayer system
	if multiplayer_system:
		multiplayer_system.set_current_area(area_id)
	
	# Load the area scene (this would be implemented to handle actual scene loading)
	_load_area_scene(area_id)
	
	# Return to playing state
	current_state = GameState.PLAYING
	
	# Emit signal
	emit_signal("area_changed", area_id, area_name)

func pause_game(paused: bool) -> void:
	"""Pause or unpause the game."""
	if paused and current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.PAUSED
		get_tree().paused = true
	elif not paused and current_state == GameState.PAUSED:
		current_state = previous_state
		get_tree().paused = false
	
	emit_signal("game_paused", paused)

func add_souls(amount: int) -> void:
	"""Add souls to the player's total."""
	player_souls += amount
	
	if player:
		player.add_souls(amount)

func spend_souls(amount: int) -> bool:
	"""Spend souls from the player's total."""
	if player_souls >= amount:
		player_souls -= amount
		
		if player:
			player.souls = player_souls
			player.emit_signal("souls_changed", player_souls)
		
		return true
	
	return false

func level_up(stat_to_increase: String) -> bool:
	"""Level up the player by increasing a stat."""
	# Calculate souls required for level up
	var required_souls = _calculate_level_up_cost()
	
	if player_souls < required_souls:
		return false
	
	# Spend souls
	if not spend_souls(required_souls):
		return false
	
	# Increase the stat
	if player_stats.has(stat_to_increase):
		player_stats[stat_to_increase] += 1
	
	# Increase player level
	player_level += 1
	
	# Apply stat changes to player
	_apply_player_stats()
	
	# Emit signal
	emit_signal("player_leveled_up", player_level)
	
	return true

func add_item_to_inventory(item_data: Dictionary) -> bool:
	"""Add an item to the player's inventory."""
	# Check if item is stackable and already exists
	if item_data.get("stackable", false):
		for item in player_inventory:
			if item.id == item_data.id:
				item.quantity += item_data.get("quantity", 1)
				emit_signal("item_acquired", item_data)
				return true
	
	# Add new item
	player_inventory.append(item_data)
	
	# Emit signal
	emit_signal("item_acquired", item_data)
	
	return true

func has_item(item_id: String) -> bool:
	"""Check if the player has a specific item."""
	for item in player_inventory:
		if item.id == item_id and item.get("quantity", 1) > 0:
			return true
	
	return false

func remove_item(item_id: String, quantity: int = 1) -> bool:
	"""Remove an item from the player's inventory."""
	for i in range(player_inventory.size()):
		var item = player_inventory[i]
		if item.id == item_id:
			if item.get("stackable", false):
				item.quantity -= quantity
				if item.quantity <= 0:
					player_inventory.remove_at(i)
			else:
				player_inventory.remove_at(i)
			return true
	
	return false

func equip_item(item_id: String, slot: String) -> bool:
	"""Equip an item to a specific slot."""
	# Find the item in inventory
	var item_data = null
	for item in player_inventory:
		if item.id == item_id:
			item_data = item
			break
	
	if not item_data:
		return false
	
	# Check if item can be equipped in the slot
	if not item_data.get("equippable", false) or item_data.get("slot", "") != slot:
		return false
	
	# Unequip current item in that slot
	if player_equipment.has(slot):
		var current_item_id = player_equipment[slot]
		# Add the current item back to inventory if it's not already there
		var found = false
		for item in player_inventory:
			if item.id == current_item_id:
				found = true
				break
		
		if not found:
			# This would need to fetch the item data from a database
			var current_item_data = _get_item_data(current_item_id)
			if current_item_data:
				player_inventory.append(current_item_data)
	
	# Equip new item
	player_equipment[slot] = item_id
	
	# Remove from inventory if it's not stackable
	if not item_data.get("stackable", false):
		remove_item(item_id)
	
	# Apply equipment to player
	if player:
		if slot == "weapon":
			player.equip_weapon(item_data)
		elif slot == "armor":
			player.equip_armor(item_data)
	
	return true

func update_quest(quest_id: String, status: String, progress: float = 0.0) -> void:
	"""Update the status of a quest."""
	if not player_quests.has(quest_id):
		player_quests[quest_id] = {
			"status": "inactive",
			"progress": 0.0,
			"completed": false
		}
	
	player_quests[quest_id].status = status
	
	if progress > 0:
		player_quests[quest_id].progress = progress
	
	if status == "completed":
		player_quests[quest_id].completed = true
	
	# Emit signal
	emit_signal("quest_updated", quest_id, status)

func unlock_achievement(achievement_id: String) -> void:
	"""Unlock an achievement."""
	if player_achievements.has(achievement_id) and player_achievements[achievement_id]:
		return
	
	player_achievements[achievement_id] = true
	
	# Emit signal
	emit_signal("achievement_unlocked", achievement_id)
	
	# Show notification
	if ui_manager and ui_manager.has_method("show_achievement"):
		ui_manager.show_achievement(achievement_id)

func show_notification(message: String, duration: float = 3.0) -> void:
	"""Show a notification message to the player."""
	if ui_manager and ui_manager.has_method("show_notification"):
		ui_manager.show_notification(message, duration)

func open_checkpoint_menu(checkpoint) -> void:
	"""Open the checkpoint (bonfire) menu."""
	if ui_manager and ui_manager.has_method("open_checkpoint_menu"):
		previous_state = current_state
		current_state = GameState.PAUSED
		ui_manager.open_checkpoint_menu(checkpoint)

func _handle_input() -> void:
	"""Handle global input."""
	if Input.is_action_just_pressed("pause") and current_state == GameState.PLAYING:
		pause_game(true)
	elif Input.is_action_just_pressed("pause") and current_state == GameState.PAUSED:
		pause_game(false)

func _initialize_player_stats() -> void:
	"""Initialize player stats for a new game."""
	player_stats = {
		"strength": 10,
		"dexterity": 10,
		"vitality": 10,
		"endurance": 10,
		"intelligence": 10,
		"faith": 10
	}

func _reset_player_for_new_game() -> void:
	"""Reset player data for a new game."""
	player_level = 1
	player_souls = 0
	_initialize_player_stats()
	player_inventory = []
	player_equipment = {}
	player_discovered_areas = []
	player_unlocked_shortcuts = []
	player_quests = {}
	player_achievements = {}
	game_time = 0.0
	death_count = 0
	
	# Apply stats to player
	_apply_player_stats()
	
	# Add starting equipment
	_add_starting_equipment()

func _apply_player_stats() -> void:
	"""Apply stats to the player character."""
	if not player:
		return
	
	player.strength = player_stats.get("strength", 10)
	player.dexterity = player_stats.get("dexterity", 10)
	player.vitality = player_stats.get("vitality", 10)
	player.endurance = player_stats.get("endurance", 10)
	player.intelligence = player_stats.get("intelligence", 10)
	player.faith = player_stats.get("faith", 10)
	
	# Update derived stats
	player.current_health = player.get_max_health()
	player.current_stamina = player.get_max_stamina()
	player.souls = player_souls

func _add_starting_equipment() -> void:
	"""Add starting equipment to the player."""
	# Add starting weapon
	var starting_weapon = {
		"id": "weapon_longsword",
		"name": "Longsword",
		"description": "A standard longsword. Well-balanced and reliable.",
		"type": "weapon",
		"subtype": "straight_sword",
		"damage": 50,
		"scaling": {"strength": 0.4, "dexterity": 0.4},
		"weight": 3.0,
		"durability": 100,
		"equippable": true,
		"slot": "weapon",
		"icon": "longsword_icon"
	}
	
	add_item_to_inventory(starting_weapon)
	equip_item("weapon_longsword", "weapon")
	
	# Add starting armor
	var starting_armor = {
		"id": "armor_knight",
		"name": "Knight Armor",
		"description": "Standard armor worn by knights.",
		"type": "armor",
		"subtype": "medium",
		"defense": {"physical": 10, "magic": 5, "fire": 5, "lightning": 5},
		"weight": 8.0,
		"poise": 10,
		"equippable": true,
		"slot": "armor",
		"icon": "knight_armor_icon"
	}
	
	add_item_to_inventory(starting_armor)
	equip_item("armor_knight", "armor")
	
	# Add estus flask
	var estus_flask = {
		"id": "item_estus_flask",
		"name": "Estus Flask",
		"description": "A flask filled with golden estus. Restores HP.",
		"type": "consumable",
		"effect": "heal",
		"effect_amount": 50,
		"uses": 3,
		"max_uses": 3,
		"stackable": false,
		"icon": "estus_flask_icon"
	}
	
	add_item_to_inventory(estus_flask)

func _calculate_level_up_cost() -> int:
	"""Calculate the soul cost for leveling up."""
	# This formula can be adjusted for balance
	return int(pow(player_level, 1.5) * 100)

func _get_item_data(item_id: String) -> Dictionary:
	"""Get item data from the item database."""
	# This would be implemented to fetch item data from a database
	# For now, we'll return an empty dictionary
	return {}

func _load_area_scene(area_id: String) -> void:
	"""Load an area scene."""
	# This would be implemented to handle actual scene loading
	print("Loading area: " + area_id)

func _check_web_save() -> void:
	"""Check for a saved game in web storage."""
	if not is_web_build:
		return
	
	# This would be implemented to check for a saved game in web storage
	# For now, we'll just print a message
	print("Checking for web save...")

func _save_to_web_storage(save_data: Dictionary) -> void:
	"""Save game data to web storage."""
	if not is_web_build:
		return
	
	# This would be implemented to save game data to web storage
	# For now, we'll just print a message
	print("Saving game to web storage...")

func _on_player_died() -> void:
	"""Handle player death."""
	death_count += 1

func _on_souls_changed(souls: int) -> void:
	"""Handle souls changed."""
	player_souls = souls

func _on_checkpoint_activated(checkpoint_id: String) -> void:
	"""Handle checkpoint activation."""
	# Save game when checkpoint is activated
	save_game()

func _on_player_respawned(checkpoint_id: String) -> void:
	"""Handle player respawn."""
	# Nothing special needed here for now
	pass

func _on_player_invasion_started(invader_data: Dictionary) -> void:
	"""Handle player invasion."""
	# Show notification
	show_notification("You are being invaded by " + invader_data.player_name + "!", 5.0)
	
	# Play invasion sound
	if sound_manager and sound_manager.has_method("play_sound"):
		sound_manager.play_sound("invasion_alert") 
