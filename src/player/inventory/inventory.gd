extends Resource
class_name Inventory

signal item_added(item)
signal item_removed(item)
signal item_used(item)
signal inventory_changed

# Maximum number of items in each category
const MAX_WEAPONS = 20
const MAX_ARMOR = 20
const MAX_CONSUMABLES = 20
const MAX_KEY_ITEMS = 30

# Item collections
@export var weapons: Array = []
@export var armor: Array = []
@export var consumables: Array = []
@export var key_items: Array = []

# Equipment slots
@export var equipped_weapon: Resource = null
@export var equipped_head: Resource = null
@export var equipped_chest: Resource = null
@export var equipped_hands: Resource = null
@export var equipped_legs: Resource = null

# Quick slots (for consumables)
@export var quick_slot_1: Resource = null
@export var quick_slot_2: Resource = null
@export var quick_slot_3: Resource = null
@export var quick_slot_4: Resource = null
@export var quick_slot_5: Resource = null

# Add an item to the appropriate collection
func add_item(item: Resource) -> bool:
    if item is WeaponData:
        if weapons.size() >= MAX_WEAPONS:
            return false
        weapons.append(item)
        emit_signal("item_added", item)
    elif item is ArmorData:
        if armor.size() >= MAX_ARMOR:
            return false
        armor.append(item)
        emit_signal("item_added", item)
    elif item is ConsumableItem:
        if consumables.size() >= MAX_CONSUMABLES:
            return false
        
        # Check if we already have this consumable
        for existing_item in consumables:
            if existing_item.id == item.id:
                existing_item.quantity += item.quantity
                emit_signal("item_added", item)
                emit_signal("inventory_changed")
                return true
        
        consumables.append(item)
        emit_signal("item_added", item)
    elif item is KeyItem:
        if key_items.size() >= MAX_KEY_ITEMS:
            return false
        key_items.append(item)
        emit_signal("item_added", item)
    else:
        return false
    
    emit_signal("inventory_changed")
    return true

# Remove an item from the inventory
func remove_item(item: Resource) -> bool:
    if item is WeaponData:
        if item == equipped_weapon:
            equipped_weapon = null
        
        if weapons.has(item):
            weapons.erase(item)
            emit_signal("item_removed", item)
            emit_signal("inventory_changed")
            return true
    elif item is ArmorData:
        # Check if it's equipped and unequip if necessary
        match item.type:
            ArmorData.ArmorType.HEAD:
                if item == equipped_head:
                    equipped_head = null
            ArmorData.ArmorType.CHEST:
                if item == equipped_chest:
                    equipped_chest = null
            ArmorData.ArmorType.HANDS:
                if item == equipped_hands:
                    equipped_hands = null
            ArmorData.ArmorType.LEGS:
                if item == equipped_legs:
                    equipped_legs = null
        
        if armor.has(item):
            armor.erase(item)
            emit_signal("item_removed", item)
            emit_signal("inventory_changed")
            return true
    elif item is ConsumableItem:
        if consumables.has(item):
            if item.quantity > 1:
                item.quantity -= 1
            else:
                # Remove from quick slots if necessary
                if item == quick_slot_1:
                    quick_slot_1 = null
                elif item == quick_slot_2:
                    quick_slot_2 = null
                elif item == quick_slot_3:
                    quick_slot_3 = null
                elif item == quick_slot_4:
                    quick_slot_4 = null
                elif item == quick_slot_5:
                    quick_slot_5 = null
                
                consumables.erase(item)
            
            emit_signal("item_removed", item)
            emit_signal("inventory_changed")
            return true
    elif item is KeyItem:
        if key_items.has(item):
            key_items.erase(item)
            emit_signal("item_removed", item)
            emit_signal("inventory_changed")
            return true
    
    return false

# Use a consumable item
func use_item(item: Resource) -> bool:
    if item is ConsumableItem and consumables.has(item):
        # Apply the item's effect (this would be handled by the item itself)
        var success = item.use()
        
        if success:
            emit_signal("item_used", item)
            
            # Remove one from quantity
            if item.quantity > 1:
                item.quantity -= 1
            else:
                # Remove from quick slots if necessary
                if item == quick_slot_1:
                    quick_slot_1 = null
                elif item == quick_slot_2:
                    quick_slot_2 = null
                elif item == quick_slot_3:
                    quick_slot_3 = null
                elif item == quick_slot_4:
                    quick_slot_4 = null
                elif item == quick_slot_5:
                    quick_slot_5 = null
                
                consumables.erase(item)
            
            emit_signal("inventory_changed")
            return true
    
    return false

# Equip a weapon
func equip_weapon(weapon: WeaponData) -> bool:
    if weapons.has(weapon):
        equipped_weapon = weapon
        emit_signal("inventory_changed")
        return true
    return false

# Equip armor
func equip_armor(armor_piece: ArmorData) -> bool:
    if armor.has(armor_piece):
        match armor_piece.type:
            ArmorData.ArmorType.HEAD:
                equipped_head = armor_piece
            ArmorData.ArmorType.CHEST:
                equipped_chest = armor_piece
            ArmorData.ArmorType.HANDS:
                equipped_hands = armor_piece
            ArmorData.ArmorType.LEGS:
                equipped_legs = armor_piece
            _:
                return false
        
        emit_signal("inventory_changed")
        return true
    return false

# Assign a consumable to a quick slot
func assign_to_quick_slot(item: Resource, slot: int) -> bool:
    if not (item is ConsumableItem and consumables.has(item)):
        return false
    
    match slot:
        1:
            quick_slot_1 = item
        2:
            quick_slot_2 = item
        3:
            quick_slot_3 = item
        4:
            quick_slot_4 = item
        5:
            quick_slot_5 = item
        _:
            return false
    
    emit_signal("inventory_changed")
    return true

# Get the total weight of all equipped items
func get_equipped_weight() -> float:
    var total_weight = 0.0
    
    if equipped_weapon:
        total_weight += equipped_weapon.weight
    
    if equipped_head:
        total_weight += equipped_head.weight
    
    if equipped_chest:
        total_weight += equipped_chest.weight
    
    if equipped_hands:
        total_weight += equipped_hands.weight
    
    if equipped_legs:
        total_weight += equipped_legs.weight
    
    return total_weight

# Get item by ID
func get_item_by_id(id: String) -> Resource:
    # Check weapons
    for weapon in weapons:
        if weapon.id == id:
            return weapon
    
    # Check armor
    for armor_piece in armor:
        if armor_piece.id == id:
            return armor_piece
    
    # Check consumables
    for consumable in consumables:
        if consumable.id == id:
            return consumable
    
    # Check key items
    for key_item in key_items:
        if key_item.id == id:
            return key_item
    
    return null

# Check if player has a specific item by ID
func has_item(id: String) -> bool:
    return get_item_by_id(id) != null

# Get the quantity of a specific consumable
func get_consumable_quantity(id: String) -> int:
    for consumable in consumables:
        if consumable.id == id:
            return consumable.quantity
    return 0 