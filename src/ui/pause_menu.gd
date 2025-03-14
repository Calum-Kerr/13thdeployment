extends Control
class_name PauseMenu

# Signals
signal resume_game
signal options_selected
signal quit_to_menu
signal quit_game

# Node references
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var inventory_button: Button = $VBoxContainer/InventoryButton
@onready var equipment_button: Button = $VBoxContainer/EquipmentButton
@onready var stats_button: Button = $VBoxContainer/StatsButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_to_menu_button: Button = $VBoxContainer/QuitToMenuButton
@onready var quit_game_button: Button = $VBoxContainer/QuitGameButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Connect button signals
	resume_button.pressed.connect(_on_resume_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	equipment_button.pressed.connect(_on_equipment_button_pressed)
	stats_button.pressed.connect(_on_stats_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_button_pressed)
	quit_game_button.pressed.connect(_on_quit_game_button_pressed)
	
	# Connect to UI Manager
	if get_node_or_null("/root/UIManager"):
		var ui_manager = get_node("/root/UIManager")
		resume_game.connect(ui_manager._on_resume_game)
		options_selected.connect(ui_manager._on_options_selected)
		quit_to_menu.connect(ui_manager._on_quit_to_menu)
		quit_game.connect(ui_manager._on_quit_game)
	
	# Play appear animation if available
	if animation_player and animation_player.has_animation("appear"):
		animation_player.play("appear")

func _on_resume_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Play disappear animation if available
	if animation_player and animation_player.has_animation("disappear"):
		animation_player.play("disappear")
		await animation_player.animation_finished
	
	# Emit resume signal
	resume_game.emit()

func _on_inventory_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Tell UIManager to show inventory
	if get_node_or_null("/root/UIManager"):
		get_node("/root/UIManager").show_inventory_menu()

func _on_equipment_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Tell UIManager to show equipment
	if get_node_or_null("/root/UIManager"):
		get_node("/root/UIManager").show_equipment_menu()

func _on_stats_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Tell UIManager to show stats
	if get_node_or_null("/root/UIManager"):
		get_node("/root/UIManager").show_stats_menu()

func _on_options_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Emit options signal
	options_selected.emit()

func _on_quit_to_menu_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Quit to Main Menu"
	dialog.dialog_text = "Are you sure you want to quit to the main menu? Any unsaved progress will be lost."
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
		quit_to_menu.emit()
	)
	
	# Show dialog
	dialog.popup_centered()

func _on_quit_game_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Quit Game"
	dialog.dialog_text = "Are you sure you want to quit the game? Any unsaved progress will be lost."
	dialog.get_ok_button().text = "Yes"
	dialog.get_cancel_button().text = "No"
	add_child(dialog)
	
	# Connect dialog signals
	dialog.confirmed.connect(func():
		# Play disappear animation if available
		if animation_player and animation_player.has_animation("disappear"):
			animation_player.play("disappear")
			await animation_player.animation_finished
		
		# Emit quit game signal
		quit_game.emit()
	)
	
	# Show dialog
	dialog.popup_centered()

func _play_button_sound():
	# Play button sound if we have an AudioStreamPlayer
	var audio_player = get_node_or_null("ButtonSound")
	if audio_player and audio_player is AudioStreamPlayer:
		audio_player.play()

func _input(event):
	# Handle escape key to resume game
	if event.is_action_pressed("pause"):
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled() 