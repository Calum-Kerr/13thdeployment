extends Control
class_name DeathScreen

# Signals
signal respawn_requested
signal quit_to_menu_requested

# Node references
@onready var death_message_label: Label = $VBoxContainer/DeathMessageLabel
@onready var souls_lost_label: Label = $VBoxContainer/SoulsLostLabel
@onready var respawn_button: Button = $VBoxContainer/ButtonsContainer/RespawnButton
@onready var quit_button: Button = $VBoxContainer/ButtonsContainer/QuitButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Death messages
const DEATH_MESSAGES = [
	"YOU DIED",
	"DEATH COMES FOR ALL",
	"THE ABYSS CLAIMS ANOTHER",
	"DARKNESS CONSUMES YOU",
	"YOUR JOURNEY ENDS HERE",
	"RETURN TO THE BONFIRE",
	"SOULS LOST TO THE VOID",
	"DEATH IS ONLY THE BEGINNING",
	"LEARN FROM FAILURE",
	"RISE AGAIN, ASHEN ONE"
]

func _ready():
	# Connect button signals
	respawn_button.pressed.connect(_on_respawn_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Connect to UI Manager
	if get_node_or_null("/root/UIManager"):
		var ui_manager = get_node("/root/UIManager")
		respawn_requested.connect(ui_manager._on_respawn_requested)
		quit_to_menu_requested.connect(ui_manager._on_quit_to_menu)
	
	# Play appear animation if available
	if animation_player and animation_player.has_animation("appear"):
		animation_player.play("appear")

func show_death_screen(souls_lost: int = 0):
	# Set random death message
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var message_index = rng.randi_range(0, DEATH_MESSAGES.size() - 1)
	death_message_label.text = DEATH_MESSAGES[message_index]
	
	# Set souls lost message
	if souls_lost > 0:
		souls_lost_label.text = "Souls Lost: " + str(souls_lost)
	else:
		souls_lost_label.text = ""
	
	# Show the screen
	visible = true
	
	# Play sound effect if available
	var audio_player = get_node_or_null("DeathSound")
	if audio_player and audio_player is AudioStreamPlayer:
		audio_player.play()

func _on_respawn_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Play disappear animation if available
	if animation_player and animation_player.has_animation("disappear"):
		animation_player.play("disappear")
		await animation_player.animation_finished
	
	# Emit respawn signal
	respawn_requested.emit()

func _on_quit_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Quit to Main Menu"
	dialog.dialog_text = "Are you sure you want to quit to the main menu?"
	dialog.get_ok_button().text = "Yes"
	dialog.get_cancel_button().text = "No"
	add_child(dialog)
	
	# Connect dialog signals
	dialog.confirmed.connect(func():
		# Play disappear animation if available
		if animation_player and animation_player.has_animation("disappear"):
			animation_player.play("disappear")
			await animation_player.animation_finished
		
		# Emit quit to menu signal
		quit_to_menu_requested.emit()
	)
	
	# Show dialog
	dialog.popup_centered()

func _play_button_sound():
	# Play button sound if we have an AudioStreamPlayer
	var audio_player = get_node_or_null("ButtonSound")
	if audio_player and audio_player is AudioStreamPlayer:
		audio_player.play()

func _input(event):
	# Handle any key or button press to respawn
	if visible and (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			_on_respawn_button_pressed()
			get_viewport().set_input_as_handled() 