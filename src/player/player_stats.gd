extends Resource
class_name PlayerStats

signal level_up(new_level: int)
signal attribute_changed(attribute: String, new_value: int)

# Character identification
@export var character_name: String = "Ashen One"
@export var character_class: String = "Knight"

# Core stats
@export var level: int = 1
@export var souls: int = 0
@export var souls_required_for_next_level: int = 673

# Attributes
@export var vigor: int = 10        # Affects HP
@export var endurance: int = 10    # Affects stamina
@export var vitality: int = 10     # Affects equip load
@export var strength: int = 10     # Affects physical damage with strength weapons
@export var dexterity: int = 10    # Affects physical damage with dexterity weapons
@export var intelligence: int = 10 # Affects magic damage
@export var faith: int = 10        # Affects miracle damage
@export var luck: int = 10         # Affects item discovery and status effects

# Derived stats
@export var max_hp: float = 400.0
@export var max_stamina: float = 100.0
@export var max_focus_points: float = 50.0
@export var equip_load: float = 40.0
@export var equip_load_percentage: float = 0.0

# Status
@export var current_hp: float = 400.0
@export var current_stamina: float = 100.0
@export var current_focus_points: float = 50.0

# Resistances
@export var physical_defense: float = 100.0
@export var magic_defense: float = 100.0
@export var fire_defense: float = 100.0
@export var lightning_defense: float = 100.0
@export var dark_defense: float = 100.0

# Status resistances
@export var poison_resistance: float = 100.0
@export var bleed_resistance: float = 100.0
@export var frost_resistance: float = 100.0
@export var curse_resistance: float = 100.0

# Initialize stats based on character class
func initialize_class(class_name: String) -> void:
    character_class = class_name
    
    # Reset to base values
    vigor = 10
    endurance = 10
    vitality = 10
    strength = 10
    dexterity = 10
    intelligence = 10
    faith = 10
    luck = 10
    
    # Adjust based on class
    match class_name:
        "Knight":
            vigor = 12
            endurance = 11
            vitality = 15
            strength = 13
            dexterity = 12
        "Mercenary":
            endurance = 12
            dexterity = 16
            luck = 11
        "Warrior":
            vigor = 11
            strength = 16
            dexterity = 9
        "Herald":
            vigor = 12
            endurance = 9
            vitality = 12
            strength = 12
            faith = 13
        "Thief":
            vigor = 10
            endurance = 14
            vitality = 9
            dexterity = 14
            luck = 14
        "Assassin":
            endurance = 11
            dexterity = 14
            intelligence = 14
            luck = 10
        "Sorcerer":
            intelligence = 16
            faith = 7
            attunement = 14
        "Pyromancer":
            endurance = 12
            intelligence = 14
            faith = 14
        "Cleric":
            vigor = 10
            strength = 12
            faith = 16
        "Deprived":
            # All stats at 10
            pass
    
    # Update derived stats
    update_derived_stats()

# Calculate souls required for next level
func calculate_souls_for_level(target_level: int) -> int:
    # Formula based on Dark Souls 3 leveling curve
    return int(pow(target_level, 3) * 0.02 + pow(target_level, 2) * 3.06 + target_level * 105.6 - 895)

# Level up a specific attribute
func level_up_attribute(attribute: String) -> bool:
    # Check if player has enough souls
    if souls < souls_required_for_next_level:
        return false
    
    # Deduct souls
    souls -= souls_required_for_next_level
    
    # Increase the attribute
    match attribute:
        "vigor":
            vigor += 1
            emit_signal("attribute_changed", "vigor", vigor)
        "endurance":
            endurance += 1
            emit_signal("attribute_changed", "endurance", endurance)
        "vitality":
            vitality += 1
            emit_signal("attribute_changed", "vitality", vitality)
        "strength":
            strength += 1
            emit_signal("attribute_changed", "strength", strength)
        "dexterity":
            dexterity += 1
            emit_signal("attribute_changed", "dexterity", dexterity)
        "intelligence":
            intelligence += 1
            emit_signal("attribute_changed", "intelligence", intelligence)
        "faith":
            faith += 1
            emit_signal("attribute_changed", "faith", faith)
        "luck":
            luck += 1
            emit_signal("attribute_changed", "luck", luck)
        _:
            # Invalid attribute
            souls += souls_required_for_next_level
            return false
    
    # Increase level
    level += 1
    
    # Calculate souls required for next level
    souls_required_for_next_level = calculate_souls_for_level(level + 1)
    
    # Update derived stats
    update_derived_stats()
    
    # Emit level up signal
    emit_signal("level_up", level)
    
    return true

# Update all derived stats based on attributes
func update_derived_stats() -> void:
    # Health
    max_hp = 400.0 + (vigor - 10) * 20.0
    
    # Stamina
    max_stamina = 100.0 + (endurance - 10) * 5.0
    
    # Focus Points (FP)
    max_focus_points = 50.0 + (intelligence - 10) * 2.0 + (faith - 10) * 2.0
    
    # Equip Load
    equip_load = 40.0 + (vitality - 10) * 1.5
    
    # Ensure current values don't exceed maximums
    current_hp = min(current_hp, max_hp)
    current_stamina = min(current_stamina, max_stamina)
    current_focus_points = min(current_focus_points, max_focus_points)

# Add souls to the player
func add_souls(amount: int) -> void:
    souls += amount

# Lose souls on death (return the amount lost)
func lose_souls() -> int:
    var souls_lost = souls
    souls = 0
    return souls_lost

# Take damage
func take_damage(amount: float, damage_type: String = "physical") -> float:
    var defense = 0.0
    
    # Get appropriate defense value
    match damage_type:
        "physical":
            defense = physical_defense
        "magic":
            defense = magic_defense
        "fire":
            defense = fire_defense
        "lightning":
            defense = lightning_defense
        "dark":
            defense = dark_defense
    
    # Calculate damage reduction (higher defense gives diminishing returns)
    var damage_reduction = defense / (defense + 100.0)
    var actual_damage = amount * (1.0 - damage_reduction)
    
    # Apply damage
    current_hp = max(0, current_hp - actual_damage)
    
    return actual_damage

# Heal the player
func heal(amount: float) -> float:
    var old_hp = current_hp
    current_hp = min(max_hp, current_hp + amount)
    return current_hp - old_hp

# Use stamina
func use_stamina(amount: float) -> bool:
    if current_stamina >= amount:
        current_stamina -= amount
        return true
    return false

# Regenerate stamina
func regenerate_stamina(amount: float) -> void:
    current_stamina = min(max_stamina, current_stamina + amount)

# Use focus points
func use_focus_points(amount: float) -> bool:
    if current_focus_points >= amount:
        current_focus_points -= amount
        return true
    return false

# Regenerate focus points
func regenerate_focus_points(amount: float) -> void:
    current_focus_points = min(max_focus_points, current_focus_points + amount)

# Calculate equip load percentage
func calculate_equip_load_percentage(current_load: float) -> void:
    equip_load_percentage = (current_load / equip_load) * 100.0

# Get movement speed multiplier based on equip load
func get_movement_speed_multiplier() -> float:
    if equip_load_percentage < 30.0:
        # Fast roll
        return 1.0
    elif equip_load_percentage < 70.0:
        # Medium roll
        return 0.9
    elif equip_load_percentage < 100.0:
        # Fat roll
        return 0.7
    else:
        # Overencumbered
        return 0.5

# Get roll type based on equip load
func get_roll_type() -> String:
    if equip_load_percentage < 30.0:
        return "fast"
    elif equip_load_percentage < 70.0:
        return "medium"
    elif equip_load_percentage < 100.0:
        return "fat"
    else:
        return "none"

# Check if player is dead
func is_dead() -> bool:
    return current_hp <= 0 