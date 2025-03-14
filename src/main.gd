extends Node

"""
Main: Entry point for the Soulsborne Web Game.
Handles scene transitions and game initialization.
"""

# Constants
const GAME_VERSION = "0.1.0"
const GAME_SCENE = "res://src/levels/game.tscn"
const OPTIONS_SCENE = "res://src/ui/options.tscn"
const CREDITS_SCENE = "res://src/ui/credits.tscn"

# Node references
@onready var main_menu = $CanvasLayer/MainMenu
@onready var version_label = $CanvasLayer/MainMenu/VersionLabel

func _ready() -> void:
	"""Initialize the main scene."""
	print("Main scene initialized")
	
	# Set version label
	version_label.text = "v" + GAME_VERSION
	
	# Initialize game systems
	_initialize_game_systems()

func _initialize_game_systems() -> void:
	"""Initialize all game systems."""
	# This will be expanded as we implement more systems
	print("Game systems initialized")

func _on_start_button_pressed() -> void:
	"""Handle start button press."""
	print("Starting game...")
	
	# Check if the game scene exists
	if ResourceLoader.exists(GAME_SCENE):
		# Transition to the game scene
		get_tree().change_scene_to_file(GAME_SCENE)
	else:
		# Show an error message if the scene doesn't exist
		print("Error: Game scene not found: " + GAME_SCENE)
		var dialog = AcceptDialog.new()
		dialog.title = "Error"
		dialog.dialog_text = "Game scene not found. The game is still under development."
		add_child(dialog)
		dialog.popup_centered()

func _on_options_button_pressed() -> void:
	"""Handle options button press."""
	print("Opening options...")
	
	# Check if the options scene exists
	if ResourceLoader.exists(OPTIONS_SCENE):
		# Transition to the options scene
		get_tree().change_scene_to_file(OPTIONS_SCENE)
	else:
		# Show an error message if the scene doesn't exist
		print("Error: Options scene not found: " + OPTIONS_SCENE)
		var dialog = AcceptDialog.new()
		dialog.title = "Error"
		dialog.dialog_text = "Options scene not found. The game is still under development."
		add_child(dialog)
		dialog.popup_centered()

func _on_credits_button_pressed() -> void:
	"""Handle credits button press."""
	print("Opening credits...")
	
	# Check if the credits scene exists
	if ResourceLoader.exists(CREDITS_SCENE):
		# Transition to the credits scene
		get_tree().change_scene_to_file(CREDITS_SCENE)
	else:
		# Show an error message if the scene doesn't exist
		print("Error: Credits scene not found: " + CREDITS_SCENE)
		var dialog = AcceptDialog.new()
		dialog.title = "Error"
		dialog.dialog_text = "Credits scene not found. The game is still under development."
		add_child(dialog)
		dialog.popup_centered()

func _on_quit_button_pressed() -> void:
	"""Handle quit button press."""
	print("Quitting game...")
	
	# Show a confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Quit Game"
	dialog.dialog_text = "Are you sure you want to quit?"
	dialog.get_ok_button().text = "Yes"
	dialog.get_cancel_button().text = "No"
	add_child(dialog)
	
	# Connect the confirmed signal
	dialog.confirmed.connect(func():
		# Quit the game
		get_tree().quit()
	)
	
	# Show the dialog
	dialog.popup_centered() 