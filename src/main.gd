extends Node

"""
Main: Entry point for the Soulsborne Web Game.
Handles scene transitions and game initialization.
"""

# Constants
const VERSION = "v0.1.0"
const GAME_SCENE = "res://src/levels/enemy_test_level.tscn"
const OPTIONS_SCENE = "res://src/ui/options.tscn"
const CREDITS_SCENE = "res://src/ui/credits.tscn"

# Node references
@onready var main_menu = $CanvasLayer/MainMenu
@onready var version_label = $CanvasLayer/MainMenu/VersionLabel
@onready var enemy_test_level = $EnemyTestLevel

func _ready() -> void:
	"""Initialize the main scene."""
	print("Main scene initialized")
	
	# Set version label
	if version_label:
		version_label.text = VERSION
	
	# Initialize game systems
	_initialize_game_systems()
	
	# Show menu, hide test level on start
	main_menu.visible = true
	enemy_test_level.process_mode = Node.PROCESS_MODE_DISABLED
	enemy_test_level.visible = false

func _initialize_game_systems() -> void:
	"""Initialize all game systems."""
	# This will be expanded as we implement more systems
	print("Game systems initialized")

func _on_start_button_pressed() -> void:
	"""Handle start button press."""
	print("Starting game...")
	
	# Hide menu, show and enable test level
	main_menu.visible = false
	enemy_test_level.process_mode = Node.PROCESS_MODE_INHERIT
	enemy_test_level.visible = true
	
	# Give focus to the game
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_options_button_pressed() -> void:
	"""Handle options button press."""
	print("Options button pressed")
	
	# Create a simple options dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Options"
	dialog.dialog_text = "Options menu is under development."
	add_child(dialog)
	
	# Show the dialog
	dialog.popup_centered()

func _on_credits_button_pressed() -> void:
	"""Handle credits button press."""
	print("Credits button pressed")
	
	# Create a simple credits dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Credits"
	dialog.dialog_text = "Soulsborne Web Game\nDeveloped with Godot Engine"
	add_child(dialog)
	
	# Show the dialog
	dialog.popup_centered()

func _on_quit_button_pressed() -> void:
	"""Handle quit button press."""
	print("Quitting game...")
	get_tree().quit()

func _input(event):
	# Return to menu when escape is pressed during gameplay
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not main_menu.visible:
			# Return to menu
			main_menu.visible = true
			enemy_test_level.process_mode = Node.PROCESS_MODE_DISABLED
			enemy_test_level.visible = false
			
			# Release mouse
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 