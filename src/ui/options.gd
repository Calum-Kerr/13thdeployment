extends Control

"""
Options: Options menu for the Soulsborne Web Game.
Handles audio and display settings.
"""

# Constants
const MAIN_SCENE = "res://src/main.tscn"
const CONFIG_FILE = "user://settings.cfg"

# Node references
@onready var master_volume_slider = $VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider = $VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider = $VBoxContainer/SFXVolumeSlider
@onready var fullscreen_check_box = $VBoxContainer/FullscreenCheckBox

# Configuration
var config = ConfigFile.new()

func _ready() -> void:
	"""Initialize the options scene."""
	print("Options scene initialized")
	
	# Load settings
	_load_settings()
	
	# Apply settings
	_apply_settings()

func _load_settings() -> void:
	"""Load settings from the configuration file."""
	var err = config.load(CONFIG_FILE)
	
	if err != OK:
		# If the file doesn't exist, use default settings
		print("No settings file found, using defaults")
		return
	
	# Load audio settings
	master_volume_slider.value = config.get_value("audio", "master_volume", 1.0)
	music_volume_slider.value = config.get_value("audio", "music_volume", 0.8)
	sfx_volume_slider.value = config.get_value("audio", "sfx_volume", 0.8)
	
	# Load display settings
	fullscreen_check_box.button_pressed = config.get_value("display", "fullscreen", false)

func _save_settings() -> void:
	"""Save settings to the configuration file."""
	# Save audio settings
	config.set_value("audio", "master_volume", master_volume_slider.value)
	config.set_value("audio", "music_volume", music_volume_slider.value)
	config.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	
	# Save display settings
	config.set_value("display", "fullscreen", fullscreen_check_box.button_pressed)
	
	# Save the file
	var err = config.save(CONFIG_FILE)
	if err != OK:
		print("Error saving settings: " + str(err))

func _apply_settings() -> void:
	"""Apply the current settings."""
	# Apply audio settings
	# This will be expanded when we implement the audio system
	print("Master Volume: " + str(master_volume_slider.value))
	print("Music Volume: " + str(music_volume_slider.value))
	print("SFX Volume: " + str(sfx_volume_slider.value))
	
	# Apply display settings
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_check_box.button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_master_volume_slider_value_changed(value: float) -> void:
	"""Handle master volume slider change."""
	print("Master volume changed to: " + str(value))
	_save_settings()
	_apply_settings()

func _on_music_volume_slider_value_changed(value: float) -> void:
	"""Handle music volume slider change."""
	print("Music volume changed to: " + str(value))
	_save_settings()
	_apply_settings()

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	"""Handle SFX volume slider change."""
	print("SFX volume changed to: " + str(value))
	_save_settings()
	_apply_settings()

func _on_fullscreen_check_box_toggled(button_pressed: bool) -> void:
	"""Handle fullscreen checkbox toggle."""
	print("Fullscreen toggled to: " + str(button_pressed))
	_save_settings()
	_apply_settings()

func _on_back_button_pressed() -> void:
	"""Handle back button press."""
	print("Returning to main menu...")
	
	# Save settings before returning
	_save_settings()
	
	# Return to the main menu
	get_tree().change_scene_to_file(MAIN_SCENE) 