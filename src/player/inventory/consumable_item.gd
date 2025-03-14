extends Resource
class_name ConsumableItem

# Item identification
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var quantity: int = 1

# Item properties
@export var max_quantity: int = 99
@export var use_time: float = 1.0  # Time in seconds to use the item
@export var can_use_while_moving: bool = false

# Effect types
enum EffectType {
    HEAL,           # Restore HP
    BUFF,           # Temporary stat boost
    CURE_STATUS,    # Remove status effects
    SOULS,          # Grant souls
    SPECIAL         # Special effect defined in use_effect
}

@export var effect_type: EffectType = EffectType.HEAL
@export var effect_value: float = 0.0  # Amount to heal, buff, etc.
@export var effect_duration: float = 0.0  # Duration of buff in seconds

# Status effects this item can cure
@export var cures_poison: bool = false
@export var cures_bleed: bool = false
@export var cures_frost: bool = false
@export var cures_curse: bool = false

# Animation to play when using
@export var use_animation: String = "use_item"

# Signal emitted when item is used
signal item_used(success: bool)

# Use the item
func use() -> bool:
    # This would be called by the player or inventory system
    # The actual effect would be applied to the player
    
    # Emit signal to notify that the item was used
    emit_signal("item_used", true)
    
    return true

# Apply the item's effect to the player
func apply_effect(player) -> bool:
    match effect_type:
        EffectType.HEAL:
            # Heal the player
            var amount_healed = player.stats.heal(effect_value)
            return amount_healed > 0
            
        EffectType.BUFF:
            # Apply a temporary buff
            player.apply_buff(id, effect_value, effect_duration)
            return true
            
        EffectType.CURE_STATUS:
            # Cure status effects
            var cured_something = false
            
            if cures_poison and player.has_status_effect("poison"):
                player.remove_status_effect("poison")
                cured_something = true
                
            if cures_bleed and player.has_status_effect("bleed"):
                player.remove_status_effect("bleed")
                cured_something = true
                
            if cures_frost and player.has_status_effect("frost"):
                player.remove_status_effect("frost")
                cured_something = true
                
            if cures_curse and player.has_status_effect("curse"):
                player.remove_status_effect("curse")
                cured_something = true
                
            return cured_something
            
        EffectType.SOULS:
            # Grant souls to the player
            player.stats.add_souls(int(effect_value))
            return true
            
        EffectType.SPECIAL:
            # Special effect defined in use_effect
            return use_special_effect(player)
            
        _:
            return false

# Override this in subclasses for special effects
func use_special_effect(player) -> bool:
    # Default implementation does nothing
    return false

# Check if the item can be used
func can_use(player) -> bool:
    match effect_type:
        EffectType.HEAL:
            # Can only use if not at full health
            return player.stats.current_hp < player.stats.max_hp
            
        EffectType.BUFF:
            # Can always apply buffs
            return true
            
        EffectType.CURE_STATUS:
            # Can only use if player has a status effect this item cures
            return (cures_poison and player.has_status_effect("poison")) or \
                   (cures_bleed and player.has_status_effect("bleed")) or \
                   (cures_frost and player.has_status_effect("frost")) or \
                   (cures_curse and player.has_status_effect("curse"))
                   
        EffectType.SOULS:
            # Can always use soul items
            return true
            
        EffectType.SPECIAL:
            # Check if special effect can be used
            return can_use_special_effect(player)
            
        _:
            return false

# Override this in subclasses for special effects
func can_use_special_effect(player) -> bool:
    # Default implementation always allows use
    return true 