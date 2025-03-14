extends Control
class_name HUD

# Node references
@onready var health_bar: ProgressBar = $HealthContainer/HealthBar
@onready var health_label: Label = $HealthContainer/HealthLabel
@onready var stamina_bar: ProgressBar = $StaminaContainer/StaminaBar
@onready var stamina_label: Label = $StaminaContainer/StaminaLabel
@onready var souls_label: Label = $SoulsContainer/SoulsLabel
@onready var equipped_weapon_icon: TextureRect = $WeaponContainer/WeaponIcon
@onready var equipped_item_icon: TextureRect = $ItemContainer/ItemIcon
@onready var item_count_label: Label = $ItemContainer/ItemCountLabel
@onready var boss_health_container: Control = $BossHealthContainer
@onready var boss_health_bar: ProgressBar = $BossHealthContainer/BossHealthBar
@onready var boss_name_label: Label = $BossHealthContainer/BossNameLabel
@onready var notification_container: Control = $NotificationContainer
@onready var notification_label: Label = $NotificationContainer/NotificationLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Constants
const NOTIFICATION_DURATION: float = 3.0

# Variables
var current_notification_timer: float = 0.0
var notification_queue: Array[String] = []
var is_showing_notification: bool = false

func _ready():
	# Hide boss health bar by default
	boss_health_container.visible = false
	
	# Hide notification by default
	notification_container.visible = false
	
	# Connect to UIManager signals
	if get_node_or_null("/root/UIManager"):
		var ui_manager = get_node("/root/UIManager")
		ui_manager.update_health.connect(_on_update_health)
		ui_manager.update_stamina.connect(_on_update_stamina)
		ui_manager.update_souls.connect(_on_update_souls)
		ui_manager.update_equipped_weapon.connect(_on_update_equipped_weapon)
		ui_manager.update_equipped_item.connect(_on_update_equipped_item)
		ui_manager.show_boss_health.connect(_on_show_boss_health)
		ui_manager.update_boss_health.connect(_on_update_boss_health)
		ui_manager.hide_boss_health.connect(_on_hide_boss_health)
		ui_manager.show_notification.connect(_on_show_notification)

func _process(delta):
	# Handle notification timer
	if is_showing_notification:
		current_notification_timer -= delta
		if current_notification_timer <= 0:
			_hide_current_notification()

func _on_update_health(current_health: float, max_health: float):
	# Update health bar and label
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "%d/%d" % [current_health, max_health]
	
	# Play animation if health is low
	if current_health < max_health * 0.25:
		if animation_player.has_animation("low_health_pulse"):
			if not animation_player.is_playing() or animation_player.current_animation != "low_health_pulse":
				animation_player.play("low_health_pulse")
	else:
		if animation_player.is_playing() and animation_player.current_animation == "low_health_pulse":
			animation_player.stop()

func _on_update_stamina(current_stamina: float, max_stamina: float):
	# Update stamina bar and label
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	stamina_label.text = "%d/%d" % [current_stamina, max_stamina]

func _on_update_souls(souls_count: int):
	# Update souls label
	souls_label.text = str(souls_count)

func _on_update_equipped_weapon(weapon_icon: Texture, weapon_name: String):
	# Update weapon icon and tooltip
	equipped_weapon_icon.texture = weapon_icon
	equipped_weapon_icon.tooltip_text = weapon_name

func _on_update_equipped_item(item_icon: Texture, item_name: String, item_count: int):
	# Update item icon, tooltip, and count
	equipped_item_icon.texture = item_icon
	equipped_item_icon.tooltip_text = item_name
	item_count_label.text = str(item_count)
	
	# Hide count if zero or negative
	item_count_label.visible = item_count > 0

func _on_show_boss_health(boss_name: String, boss_health: float, boss_max_health: float):
	# Show boss health container
	boss_health_container.visible = true
	
	# Set boss name
	boss_name_label.text = boss_name
	
	# Set boss health
	boss_health_bar.max_value = boss_max_health
	boss_health_bar.value = boss_health
	
	# Play animation if available
	if animation_player.has_animation("boss_health_appear"):
		animation_player.play("boss_health_appear")

func _on_update_boss_health(boss_health: float, boss_max_health: float):
	# Update boss health bar
	boss_health_bar.max_value = boss_max_health
	boss_health_bar.value = boss_health

func _on_hide_boss_health():
	# Play hide animation if available
	if animation_player.has_animation("boss_health_disappear"):
		animation_player.play("boss_health_disappear")
		await animation_player.animation_finished
	
	# Hide boss health container
	boss_health_container.visible = false

func _on_show_notification(message: String):
	# Add notification to queue
	notification_queue.append(message)
	
	# Show notification if not already showing one
	if not is_showing_notification:
		_show_next_notification()

func _show_next_notification():
	# Check if there are notifications in the queue
	if notification_queue.size() > 0:
		# Get next notification
		var message = notification_queue.pop_front()
		
		# Set notification text
		notification_label.text = message
		
		# Show notification container
		notification_container.visible = true
		
		# Play animation if available
		if animation_player.has_animation("notification_appear"):
			animation_player.play("notification_appear")
		
		# Set timer
		current_notification_timer = NOTIFICATION_DURATION
		is_showing_notification = true

func _hide_current_notification():
	# Play hide animation if available
	if animation_player.has_animation("notification_disappear"):
		animation_player.play("notification_disappear")
		await animation_player.animation_finished
	
	# Hide notification container
	notification_container.visible = false
	
	# Reset flag
	is_showing_notification = false
	
	# Show next notification if available
	if notification_queue.size() > 0:
		_show_next_notification() 