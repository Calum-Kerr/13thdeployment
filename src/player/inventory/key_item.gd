extends Resource
class_name KeyItem

# Item identification
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D

# Item properties
@export var is_quest_item: bool = true
@export var can_be_discarded: bool = false

# Associated quest or area
@export var associated_quest: String = ""
@export var unlocks_area: String = ""

# Lore text (shown when examining the item)
@export_multiline var lore_text: String = ""

# Signal emitted when item is examined
signal item_examined

# Examine the item (show lore text)
func examine() -> String:
    emit_signal("item_examined")
    return lore_text

# Check if this item unlocks a specific area or door
func unlocks(area_or_door_id: String) -> bool:
    return unlocks_area == area_or_door_id 