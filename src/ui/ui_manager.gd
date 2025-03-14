extends Node

"""
UIManager: Manages all UI elements in the game.
Handles HUD, menus, notifications, and other UI components.
"""

# Signal declarations
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal notification_shown(message: String)
signal achievement_shown(achievement_id: String)

# UI state
var current_menu: String = ""
var previous_menu: String = ""
var menu_stack: Array = []
var is_hud_visible: bool = true
var is_notification_visible: bool = false
var is_achievement_visible: bool = false

# UI references
@onready var hud: Control = $HUD
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var inventory_menu: Control = $InventoryMenu
@onready var equipment_menu: Control = $EquipmentMenu
@onready var stats_menu: Control = $StatsMenu
@onready var level_up_menu: Control = $LevelUpMenu
@onready var checkpoint_menu: Control = $CheckpointMenu
@onready var fast_travel_menu: Control = $FastTravelMenu
@onready var notification_panel: Control = $NotificationPanel
@onready var achievement_panel: Control = $AchievementPanel
@onready var loading_screen: Control = $LoadingScreen
@onready var death_screen: Control = $DeathScreen
@onready var dialog_panel: Control = $DialogPanel

# References to other systems
var game_manager = null

# UI data
var achievement_data: Dictionary = {}
var item_data: Dictionary = {}
var area_data: Dictionary = {}

func _ready() -> void:
	"""Initialize the UI manager."""
	# Find game manager
	game_manager = get_node_or_null("/root/GameManager")
	
	# Connect signals
	_connect_signals()
	
	# Hide all menus initially
	_hide_all_menus()
	
	# Show main menu
	show_main_menu()
	
	# Load UI data
	_load_ui_data()

func _process(delta: float) -> void:
	"""Process UI logic."""
	# Handle UI-specific input
	_handle_ui_input()

func _connect_signals() -> void:
	"""Connect signals between UI elements and other systems."""
	if game_manager:
		game_manager.connect("game_started", Callable(self, "_on_game_started"))
		game_manager.connect("game_paused", Callable(self, "_on_game_paused"))
		game_manager.connect("player_leveled_up", Callable(self, "_on_player_leveled_up"))
		game_manager.connect("item_acquired", Callable(self, "_on_item_acquired"))
		game_manager.connect("achievement_unlocked", Callable(self, "_on_achievement_unlocked"))
	
	# Connect UI element signals
	if main_menu:
		main_menu.connect("start_game_pressed", Callable(self, "_on_start_game_pressed"))
		main_menu.connect("load_game_pressed", Callable(self, "_on_load_game_pressed"))
		main_menu.connect("options_pressed", Callable(self, "_on_options_pressed"))
		main_menu.connect("quit_pressed", Callable(self, "_on_quit_pressed"))
	
	if pause_menu:
		pause_menu.connect("resume_pressed", Callable(self, "_on_resume_pressed"))
		pause_menu.connect("inventory_pressed", Callable(self, "_on_inventory_pressed"))
		pause_menu.connect("equipment_pressed", Callable(self, "_on_equipment_pressed"))
		pause_menu.connect("stats_pressed", Callable(self, "_on_stats_pressed"))
		pause_menu.connect("options_pressed", Callable(self, "_on_options_pressed"))
		pause_menu.connect("quit_to_menu_pressed", Callable(self, "_on_quit_to_menu_pressed"))

func _hide_all_menus() -> void:
	"""Hide all menu screens."""
	if main_menu:
		main_menu.visible = false
	
	if pause_menu:
		pause_menu.visible = false
	
	if inventory_menu:
		inventory_menu.visible = false
	
	if equipment_menu:
		equipment_menu.visible = false
	
	if stats_menu:
		stats_menu.visible = false
	
	if level_up_menu:
		level_up_menu.visible = false
	
	if checkpoint_menu:
		checkpoint_menu.visible = false
	
	if fast_travel_menu:
		fast_travel_menu.visible = false
	
	if loading_screen:
		loading_screen.visible = false
	
	if death_screen:
		death_screen.visible = false
	
	if dialog_panel:
		dialog_panel.visible = false

func _load_ui_data() -> void:
	"""Load data for UI elements."""
	# Load achievement data
	# This would load from a data file in a real implementation
	achievement_data = {
		"achievement_first_death": {
			"title": "First Steps",
			"description": "Die for the first time.",
			"icon": "achievement_first_death_icon"
		},
		"achievement_first_boss": {
			"title": "Boss Slayer",
			"description": "Defeat your first boss.",
			"icon": "achievement_first_boss_icon"
		}
	}
	
	# Load item data
	# This would load from a data file in a real implementation
	item_data = {
		"weapon_longsword": {
			"name": "Longsword",
			"description": "A standard longsword. Well-balanced and reliable.",
			"icon": "longsword_icon"
		},
		"item_estus_flask": {
			"name": "Estus Flask",
			"description": "A flask filled with golden estus. Restores HP.",
			"icon": "estus_flask_icon"
		}
	}
	
	# Load area data
	# This would load from a data file in a real implementation
	area_data = {
		"tutorial_area": {
			"name": "Abandoned Crypt",
			"description": "A forgotten burial ground where the undead first awaken.",
			"icon": "tutorial_area_icon"
		},
		"hub_area": {
			"name": "Firelink Shrine",
			"description": "A sanctuary for the unkindled, where paths to all lands converge.",
			"icon": "hub_area_icon"
		}
	}

func _handle_ui_input() -> void:
	"""Handle UI-specific input."""
	# Handle escape key for menus
	if Input.is_action_just_pressed("ui_cancel"):
		if current_menu != "" and current_menu != "main_menu":
			close_current_menu()

func update_hud(player_data: Dictionary) -> void:
	"""Update the HUD with player data."""
	if not hud or not hud.visible:
		return
	
	# Update health bar
	if hud.has_node("HealthBar"):
		var health_bar = hud.get_node("HealthBar")
		health_bar.value = player_data.get("current_health", 0)
		health_bar.max_value = player_data.get("max_health", 100)
	
	# Update stamina bar
	if hud.has_node("StaminaBar"):
		var stamina_bar = hud.get_node("StaminaBar")
		stamina_bar.value = player_data.get("current_stamina", 0)
		stamina_bar.max_value = player_data.get("max_stamina", 100)
	
	# Update souls counter
	if hud.has_node("SoulsCounter"):
		var souls_counter = hud.get_node("SoulsCounter")
		souls_counter.text = str(player_data.get("souls", 0))
	
	# Update equipped items
	if hud.has_node("EquippedItems"):
		var equipped_items = hud.get_node("EquippedItems")
		# This would update the equipped items display
		pass

func show_notification(message: String, duration: float = 3.0) -> void:
	"""Show a notification message."""
	if not notification_panel:
		return
	
	# Set notification text
	if notification_panel.has_node("NotificationLabel"):
		var label = notification_panel.get_node("NotificationLabel")
		label.text = message
	
	# Show notification
	notification_panel.visible = true
	is_notification_visible = true
	
	# Hide after duration
	await get_tree().create_timer(duration).timeout
	
	if is_notification_visible:
		notification_panel.visible = false
		is_notification_visible = false
	
	emit_signal("notification_shown", message)

func show_achievement(achievement_id: String) -> void:
	"""Show an achievement notification."""
	if not achievement_panel or not achievement_data.has(achievement_id):
		return
	
	var achievement = achievement_data[achievement_id]
	
	# Set achievement data
	if achievement_panel.has_node("AchievementTitle"):
		var title_label = achievement_panel.get_node("AchievementTitle")
		title_label.text = achievement.title
	
	if achievement_panel.has_node("AchievementDescription"):
		var desc_label = achievement_panel.get_node("AchievementDescription")
		desc_label.text = achievement.description
	
	if achievement_panel.has_node("AchievementIcon"):
		var icon = achievement_panel.get_node("AchievementIcon")
		# This would set the icon texture
		pass
	
	# Show achievement panel
	achievement_panel.visible = true
	is_achievement_visible = true
	
	# Hide after duration
	await get_tree().create_timer(5.0).timeout
	
	if is_achievement_visible:
		achievement_panel.visible = false
		is_achievement_visible = false
	
	emit_signal("achievement_shown", achievement_id)

func show_dialog(npc_name: String, dialog_text: String, options: Array = []) -> void:
	"""Show a dialog with an NPC."""
	if not dialog_panel:
		return
	
	# Set dialog data
	if dialog_panel.has_node("NPCNameLabel"):
		var name_label = dialog_panel.get_node("NPCNameLabel")
		name_label.text = npc_name
	
	if dialog_panel.has_node("DialogTextLabel"):
		var text_label = dialog_panel.get_node("DialogTextLabel")
		text_label.text = dialog_text
	
	if dialog_panel.has_node("DialogOptions"):
		var options_container = dialog_panel.get_node("DialogOptions")
		# Clear existing options
		for child in options_container.get_children():
			child.queue_free()
		
		# Add new options
		for option in options:
			var button = Button.new()
			button.text = option.text
			button.connect("pressed", Callable(self, "_on_dialog_option_selected").bind(option.id))
			options_container.add_child(button)
	
	# Show dialog panel
	dialog_panel.visible = true
	
	# Store previous menu
	previous_menu = current_menu
	current_menu = "dialog"
	
	emit_signal("menu_opened", "dialog")

func close_dialog() -> void:
	"""Close the dialog panel."""
	if not dialog_panel or not dialog_panel.visible:
		return
	
	dialog_panel.visible = false
	
	# Restore previous menu
	current_menu = previous_menu
	previous_menu = ""
	
	emit_signal("menu_closed", "dialog")

func show_loading_screen(area_name: String) -> void:
	"""Show the loading screen."""
	if not loading_screen:
		return
	
	# Set loading screen data
	if loading_screen.has_node("AreaNameLabel"):
		var area_label = loading_screen.get_node("AreaNameLabel")
		area_label.text = area_name
	
	# Show loading screen
	loading_screen.visible = true
	
	# Hide all other UI
	is_hud_visible = hud.visible
	hud.visible = false
	_hide_all_menus()

func hide_loading_screen() -> void:
	"""Hide the loading screen."""
	if not loading_screen or not loading_screen.visible:
		return
	
	loading_screen.visible = false
	
	# Restore HUD if it was visible
	if is_hud_visible:
		hud.visible = true

func show_death_screen() -> void:
	"""Show the death screen."""
	if not death_screen:
		return
	
	# Show death screen
	death_screen.visible = true
	
	# Hide HUD
	if hud:
		hud.visible = false

func hide_death_screen() -> void:
	"""Hide the death screen."""
	if not death_screen or not death_screen.visible:
		return
	
	death_screen.visible = false
	
	# Restore HUD
	if hud:
		hud.visible = true

func show_main_menu() -> void:
	"""Show the main menu."""
	_hide_all_menus()
	
	if main_menu:
		main_menu.visible = true
	
	if hud:
		hud.visible = false
	
	current_menu = "main_menu"
	menu_stack = ["main_menu"]
	
	emit_signal("menu_opened", "main_menu")

func show_pause_menu() -> void:
	"""Show the pause menu."""
	if pause_menu:
		pause_menu.visible = true
	
	previous_menu = current_menu
	current_menu = "pause_menu"
	menu_stack.push_back("pause_menu")
	
	emit_signal("menu_opened", "pause_menu")

func show_inventory_menu() -> void:
	"""Show the inventory menu."""
	if inventory_menu:
		inventory_menu.visible = true
		
		# Update inventory display
		_update_inventory_display()
	
	previous_menu = current_menu
	current_menu = "inventory_menu"
	menu_stack.push_back("inventory_menu")
	
	emit_signal("menu_opened", "inventory_menu")

func show_equipment_menu() -> void:
	"""Show the equipment menu."""
	if equipment_menu:
		equipment_menu.visible = true
		
		# Update equipment display
		_update_equipment_display()
	
	previous_menu = current_menu
	current_menu = "equipment_menu"
	menu_stack.push_back("equipment_menu")
	
	emit_signal("menu_opened", "equipment_menu")

func show_stats_menu() -> void:
	"""Show the stats menu."""
	if stats_menu:
		stats_menu.visible = true
		
		# Update stats display
		_update_stats_display()
	
	previous_menu = current_menu
	current_menu = "stats_menu"
	menu_stack.push_back("stats_menu")
	
	emit_signal("menu_opened", "stats_menu")

func show_level_up_menu() -> void:
	"""Show the level up menu."""
	if level_up_menu:
		level_up_menu.visible = true
		
		# Update level up display
		_update_level_up_display()
	
	previous_menu = current_menu
	current_menu = "level_up_menu"
	menu_stack.push_back("level_up_menu")
	
	emit_signal("menu_opened", "level_up_menu")

func open_checkpoint_menu(checkpoint) -> void:
	"""Open the checkpoint (bonfire) menu."""
	if checkpoint_menu:
		checkpoint_menu.visible = true
		
		# Store checkpoint reference
		checkpoint_menu.current_checkpoint = checkpoint
		
		# Update checkpoint menu display
		_update_checkpoint_menu_display(checkpoint)
	
	previous_menu = current_menu
	current_menu = "checkpoint_menu"
	menu_stack.push_back("checkpoint_menu")
	
	emit_signal("menu_opened", "checkpoint_menu")

func show_fast_travel_menu() -> void:
	"""Show the fast travel menu."""
	if fast_travel_menu:
		fast_travel_menu.visible = true
		
		# Update fast travel display
		_update_fast_travel_display()
	
	previous_menu = current_menu
	current_menu = "fast_travel_menu"
	menu_stack.push_back("fast_travel_menu")
	
	emit_signal("menu_opened", "fast_travel_menu")

func close_current_menu() -> void:
	"""Close the currently open menu."""
	if menu_stack.size() <= 1:
		return
	
	# Hide current menu
	var menu_to_close = menu_stack.pop_back()
	
	match menu_to_close:
		"pause_menu":
			if pause_menu:
				pause_menu.visible = false
		"inventory_menu":
			if inventory_menu:
				inventory_menu.visible = false
		"equipment_menu":
			if equipment_menu:
				equipment_menu.visible = false
		"stats_menu":
			if stats_menu:
				stats_menu.visible = false
		"level_up_menu":
			if level_up_menu:
				level_up_menu.visible = false
		"checkpoint_menu":
			if checkpoint_menu:
				checkpoint_menu.visible = false
		"fast_travel_menu":
			if fast_travel_menu:
				fast_travel_menu.visible = false
	
	# Set current menu to the top of the stack
	current_menu = menu_stack.back()
	
	emit_signal("menu_closed", menu_to_close)
	
	# If we're closing to the main menu, make sure HUD is hidden
	if current_menu == "main_menu" and hud:
		hud.visible = false
	
	# If we're closing to the game, unpause
	if current_menu == "" and game_manager:
		game_manager.pause_game(false)

func _update_inventory_display() -> void:
	"""Update the inventory display with current items."""
	if not inventory_menu or not game_manager:
		return
	
	# This would update the inventory display with items from game_manager.player_inventory
	pass

func _update_equipment_display() -> void:
	"""Update the equipment display with current equipment."""
	if not equipment_menu or not game_manager:
		return
	
	# This would update the equipment display with items from game_manager.player_equipment
	pass

func _update_stats_display() -> void:
	"""Update the stats display with current player stats."""
	if not stats_menu or not game_manager:
		return
	
	# This would update the stats display with stats from game_manager.player_stats
	pass

func _update_level_up_display() -> void:
	"""Update the level up display with current player stats and costs."""
	if not level_up_menu or not game_manager:
		return
	
	# This would update the level up display with stats from game_manager.player_stats
	# and the cost to level up from game_manager._calculate_level_up_cost()
	pass

func _update_checkpoint_menu_display(checkpoint) -> void:
	"""Update the checkpoint menu display."""
	if not checkpoint_menu:
		return
	
	# Set checkpoint name
	if checkpoint_menu.has_node("CheckpointNameLabel"):
		var name_label = checkpoint_menu.get_node("CheckpointNameLabel")
		name_label.text = checkpoint.get_display_name()
	
	# This would update the checkpoint menu options based on available actions
	pass

func _update_fast_travel_display() -> void:
	"""Update the fast travel display with available destinations."""
	if not fast_travel_menu or not game_manager or not game_manager.checkpoint_system:
		return
	
	var checkpoint_system = game_manager.checkpoint_system
	var discovered_checkpoints = checkpoint_system.get_discovered_checkpoints()
	
	# This would update the fast travel display with the discovered checkpoints
	pass

func _on_game_started() -> void:
	"""Handle game started event."""
	# Hide main menu
	if main_menu:
		main_menu.visible = false
	
	# Show HUD
	if hud:
		hud.visible = true
	
	current_menu = ""
	menu_stack = [""]

func _on_game_paused(is_paused: bool) -> void:
	"""Handle game paused event."""
	if is_paused:
		show_pause_menu()
	else:
		if current_menu == "pause_menu":
			close_current_menu()

func _on_player_leveled_up(new_level: int) -> void:
	"""Handle player level up event."""
	show_notification("Level up! You are now level " + str(new_level))

func _on_item_acquired(item_data: Dictionary) -> void:
	"""Handle item acquired event."""
	show_notification("Acquired: " + item_data.get("name", "Unknown Item"))

func _on_achievement_unlocked(achievement_id: String) -> void:
	"""Handle achievement unlocked event."""
	show_achievement(achievement_id)

func _on_start_game_pressed() -> void:
	"""Handle start game button pressed."""
	if game_manager:
		game_manager.start_game()

func _on_load_game_pressed() -> void:
	"""Handle load game button pressed."""
	if game_manager:
		# This would show a load game menu
		pass

func _on_options_pressed() -> void:
	"""Handle options button pressed."""
	# This would show an options menu
	pass

func _on_quit_pressed() -> void:
	"""Handle quit button pressed."""
	get_tree().quit()

func _on_resume_pressed() -> void:
	"""Handle resume button pressed."""
	if game_manager:
		game_manager.pause_game(false)

func _on_inventory_pressed() -> void:
	"""Handle inventory button pressed."""
	show_inventory_menu()

func _on_equipment_pressed() -> void:
	"""Handle equipment button pressed."""
	show_equipment_menu()

func _on_stats_pressed() -> void:
	"""Handle stats button pressed."""
	show_stats_menu()

func _on_quit_to_menu_pressed() -> void:
	"""Handle quit to menu button pressed."""
	if game_manager:
		game_manager.pause_game(false)
		show_main_menu()
		
		# This would need to clean up the game state
		pass

func _on_dialog_option_selected(option_id: String) -> void:
	"""Handle dialog option selected."""
	# This would handle the selected dialog option
	pass 