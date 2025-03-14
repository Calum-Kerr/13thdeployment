extends Resource
class_name ArmorData

# Armor identification
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D

# Armor type
enum ArmorType {HEAD, CHEST, HANDS, LEGS}
@export var type: ArmorType = ArmorType.CHEST

# Armor stats
@export var physical_defense: float = 5.0
@export var magic_defense: float = 0.0
@export var fire_defense: float = 0.0
@export var lightning_defense: float = 0.0
@export var dark_defense: float = 0.0

@export var poise: float = 5.0  # Resistance to staggering
@export var weight: float = 5.0

# Resistances
@export var bleed_resistance: float = 0.0
@export var poison_resistance: float = 0.0
@export var frost_resistance: float = 0.0
@export var curse_resistance: float = 0.0

# Special effects
@export var has_special_effect: bool = false
@export var special_effect_description: String = ""

# Armor model
@export var model_path: String = ""

# Calculate total defense against a specific damage type
func calculate_defense(damage_type: String) -> float:
    match damage_type:
        "physical":
            return physical_defense
        "magic":
            return magic_defense
        "fire":
            return fire_defense
        "lightning":
            return lightning_defense
        "dark":
            return dark_defense
        _:
            return 0.0

# Calculate damage reduction percentage (0-100%)
func calculate_damage_reduction(damage_type: String) -> float:
    var defense = calculate_defense(damage_type)
    # Formula: Higher defense gives diminishing returns
    # 100 defense = ~50% reduction, 200 defense = ~66% reduction
    return 100.0 * (defense / (defense + 100.0))

# Calculate status resistance percentage (0-100%)
func calculate_status_resistance(status_type: String) -> float:
    match status_type:
        "bleed":
            return bleed_resistance
        "poison":
            return poison_resistance
        "frost":
            return frost_resistance
        "curse":
            return curse_resistance
        _:
            return 0.0 