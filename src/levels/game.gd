extends Node

"""
Game: Main game scene for the Soulsborne Web Game.
This is a placeholder that will be expanded as we implement more features.
"""

# Constants
const MAIN_SCENE = "res://src/main.tscn"

func _ready() -> void:
	"""Initialize the game scene."""
	print("Game scene initialized")

func _on_back_button_pressed() -> void:
	"""Handle back button press."""
	print("Returning to main menu...")
	
	# Show a confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Return to Main Menu"
	dialog.dialog_text = "Are you sure you want to return to the main menu? Any unsaved progress will be lost."
	dialog.get_ok_button().text = "Yes"
	dialog.get_cancel_button().text = "No"
	add_child(dialog)
	
	# Connect the confirmed signal
	dialog.confirmed.connect(func():
		# Return to the main menu
		get_tree().change_scene_to_file(MAIN_SCENE)
	)
	
	# Show the dialog
	dialog.popup_centered() 