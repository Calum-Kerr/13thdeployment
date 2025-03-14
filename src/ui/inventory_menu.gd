extends Control
class_name InventoryMenu

# Signals
signal item_used(item_id: String)
signal item_equipped(item_id: String)
signal item_dropped(item_id: String)
signal back_pressed

# Node references
@onready var item_list: ItemList = $VBoxContainer/ItemList
@onready var item_description: RichTextLabel = $VBoxContainer/DescriptionPanel/ItemDescription
@onready var item_stats: RichTextLabel = $VBoxContainer/StatsPanel/ItemStats
@onready var use_button: Button = $VBoxContainer/ButtonsContainer/UseButton
@onready var equip_button: Button = $VBoxContainer/ButtonsContainer/EquipButton
@onready var drop_button: Button = $VBoxContainer/ButtonsContainer/DropButton
@onready var back_button: Button = $VBoxContainer/ButtonsContainer/BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Item data
var items: Array = []
var selected_item_index: int = -1

func _ready():
	# Connect button signals
	use_button.pressed.connect(_on_use_button_pressed)
	equip_button.pressed.connect(_on_equip_button_pressed)
	drop_button.pressed.connect(_on_drop_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect item list signals
	item_list.item_selected.connect(_on_item_selected)
	item_list.item_activated.connect(_on_item_activated)
	
	# Connect to UI Manager
	if get_node_or_null("/root/UIManager"):
		var ui_manager = get_node("/root/UIManager")
		item_used.connect(ui_manager._on_item_used)
		item_equipped.connect(ui_manager._on_item_equipped)
		item_dropped.connect(ui_manager._on_item_dropped)
		back_pressed.connect(ui_manager._on_inventory_closed)
	
	# Disable action buttons by default
	_update_button_states()
	
	# Play appear animation if available
	if animation_player and animation_player.has_animation("appear"):
		animation_player.play("appear")

func set_items(new_items: Array):
	# Store items
	items = new_items
	
	# Clear item list
	item_list.clear()
	
	# Add items to list
	for item in items:
		var icon = item.get("icon")
		var name = item.get("name", "Unknown Item")
		var count = item.get("count", 1)
		
		# Add item to list
		if count > 1:
			item_list.add_item(name + " x" + str(count), icon)
		else:
			item_list.add_item(name, icon)
	
	# Reset selection
	selected_item_index = -1
	_update_item_details()
	_update_button_states()

func _on_item_selected(index: int):
	# Store selected index
	selected_item_index = index
	
	# Update item details
	_update_item_details()
	
	# Update button states
	_update_button_states()

func _on_item_activated(index: int):
	# Store selected index
	selected_item_index = index
	
	# Update item details
	_update_item_details()
	
	# Update button states
	_update_button_states()
	
	# Determine action based on item type
	if selected_item_index >= 0 and selected_item_index < items.size():
		var item = items[selected_item_index]
		var item_type = item.get("type", "")
		
		if item_type == "consumable":
			_on_use_button_pressed()
		elif item_type == "weapon" or item_type == "armor":
			_on_equip_button_pressed()
	
func _update_item_details():
	if selected_item_index >= 0 and selected_item_index < items.size():
		var item = items[selected_item_index]
		
		# Set description
		item_description.text = item.get("description", "No description available.")
		
		# Set stats based on item type
		var stats_text = ""
		var item_type = item.get("type", "")
		
		if item_type == "weapon":
			stats_text += "Type: Weapon\n"
			stats_text += "Attack: " + str(item.get("attack", 0)) + "\n"
			stats_text += "Scaling: " + item.get("scaling", "None") + "\n"
			stats_text += "Weight: " + str(item.get("weight", 0)) + "\n"
			stats_text += "Durability: " + str(item.get("durability", 100)) + "\n"
		elif item_type == "armor":
			stats_text += "Type: Armor\n"
			stats_text += "Defense: " + str(item.get("defense", 0)) + "\n"
			stats_text += "Weight: " + str(item.get("weight", 0)) + "\n"
			stats_text += "Durability: " + str(item.get("durability", 100)) + "\n"
		elif item_type == "consumable":
			stats_text += "Type: Consumable\n"
			stats_text += "Effect: " + item.get("effect_description", "Unknown") + "\n"
			stats_text += "Count: " + str(item.get("count", 1)) + "\n"
		else:
			stats_text += "Type: Key Item\n"
		
		item_stats.text = stats_text
	else:
		# Clear details if no item selected
		item_description.text = ""
		item_stats.text = ""

func _update_button_states():
	if selected_item_index >= 0 and selected_item_index < items.size():
		var item = items[selected_item_index]
		var item_type = item.get("type", "")
		
		# Enable/disable buttons based on item type
		use_button.disabled = item_type != "consumable"
		equip_button.disabled = item_type != "weapon" and item_type != "armor"
		drop_button.disabled = item.get("can_drop", true) == false
	else:
		# Disable all buttons if no item selected
		use_button.disabled = true
		equip_button.disabled = true
		drop_button.disabled = true

func _on_use_button_pressed():
	if selected_item_index >= 0 and selected_item_index < items.size():
		var item = items[selected_item_index]
		
		# Play button sound
		_play_button_sound()
		
		# Emit signal with item ID
		item_used.emit(item.get("id", ""))
		
		# Update item count
		var count = item.get("count", 1)
		if count > 1:
			item["count"] = count - 1
			item_list.set_item_text(selected_item_index, item.get("name", "Unknown Item") + " x" + str(count - 1))
		else:
			# Remove item if count reaches 0
			items.remove_at(selected_item_index)
			item_list.remove_item(selected_item_index)
			
			# Update selection
			if items.size() > 0:
				if selected_item_index >= items.size():
					selected_item_index = items.size() - 1
				item_list.select(selected_item_index)
				_on_item_selected(selected_item_index)
			else:
				selected_item_index = -1
				_update_item_details()
		
		# Update button states
		_update_button_states()

func _on_equip_button_pressed():
	if selected_item_index >= 0 and selected_item_index < items.size():
		var item = items[selected_item_index]
		
		# Play button sound
		_play_button_sound()
		
		# Emit signal with item ID
		item_equipped.emit(item.get("id", ""))

func _on_drop_button_pressed():
	if selected_item_index >= 0 and selected_item_index < items.size():
		var item = items[selected_item_index]
		
		# Show confirmation dialog
		var dialog = ConfirmationDialog.new()
		dialog.title = "Drop Item"
		dialog.dialog_text = "Are you sure you want to drop " + item.get("name", "this item") + "?"
		dialog.get_ok_button().text = "Yes"
		dialog.get_cancel_button().text = "No"
		add_child(dialog)
		
		# Connect dialog signals
		dialog.confirmed.connect(func():
			# Play button sound
			_play_button_sound()
			
			# Emit signal with item ID
			item_dropped.emit(item.get("id", ""))
			
			# Remove item from list
			items.remove_at(selected_item_index)
			item_list.remove_item(selected_item_index)
			
			# Update selection
			if items.size() > 0:
				if selected_item_index >= items.size():
					selected_item_index = items.size() - 1
				item_list.select(selected_item_index)
				_on_item_selected(selected_item_index)
			else:
				selected_item_index = -1
				_update_item_details()
			
			# Update button states
			_update_button_states()
		)
		
		# Show dialog
		dialog.popup_centered()

func _on_back_button_pressed():
	# Play button sound
	_play_button_sound()
	
	# Play disappear animation if available
	if animation_player and animation_player.has_animation("disappear"):
		animation_player.play("disappear")
		await animation_player.animation_finished
	
	# Emit back signal
	back_pressed.emit()

func _play_button_sound():
	# Play button sound if we have an AudioStreamPlayer
	var audio_player = get_node_or_null("ButtonSound")
	if audio_player and audio_player is AudioStreamPlayer:
		audio_player.play()

func _input(event):
	# Handle escape key to go back
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled() 