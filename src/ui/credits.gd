extends Control

"""
Credits: Credits screen for the Soulsborne Web Game.
Displays credits for the game.
"""

# Constants
const MAIN_SCENE = "res://src/main.tscn"

func _ready() -> void:
	"""Initialize the credits scene."""
	print("Credits scene initialized")

func _on_back_button_pressed() -> void:
	"""Handle back button press."""
	print("Returning to main menu...")
	
	# Return to the main menu
	get_tree().change_scene_to_file(MAIN_SCENE) 