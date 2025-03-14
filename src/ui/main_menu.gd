extends Control
class_name MainMenu

# Signals
signal start_game
signal options_selected
signal credits_selected
signal quit_selected

# Node references
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var title_label: Label = $TitleLabel
@onready var background: TextureRect = $Background
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Game version
const VERSION = "0.1.0"

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Set version label
	version_label.text = "v" + VERSION
	
	# Play intro animation
	if animation_player.has_animation("intro"):
		animation_player.play("intro")
	
	# Connect to UI Manager
	if get_node_or_null("/root/UIManager"):
		start_game.connect(get_node("/root/UIManager")._on_game_start)

func _on_start_button_pressed():
	# Play button press sound
	_play_button_sound()
	
	# Emit signal to start the game
	start_game.emit()
	
	# Fade out animation
	if animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		await animation_player.animation_finished
	
	# The UIManager will handle the actual scene transition

func _on_options_button_pressed():
	# Play button press sound
	_play_button_sound()
	
	# Emit signal for options menu
	options_selected.emit()
	
	# The UIManager will handle showing the options menu

func _on_credits_button_pressed():
	# Play button press sound
	_play_button_sound()
	
	# Emit signal for credits screen
	credits_selected.emit()
	
	# The UIManager will handle showing the credits

func _on_quit_button_pressed():
	# Play button press sound
	_play_button_sound()
	
	# Emit signal for quitting
	quit_selected.emit()
	
	# Fade out animation
	if animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		await animation_player.animation_finished
	
	# Quit the game
	get_tree().quit()

func _play_button_sound():
	# Play button sound if we have an AudioStreamPlayer
	var audio_player = get_node_or_null("ButtonSound")
	if audio_player and audio_player is AudioStreamPlayer:
		audio_player.play()

func _input(event):
	# Handle keyboard/gamepad navigation
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed() 