extends Resource
class_name WeaponData

# Weapon identification
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D

# Weapon type and category
enum WeaponType {SWORD, AXE, SPEAR, HAMMER, DAGGER, BOW, STAFF, SHIELD}
@export var type: WeaponType = WeaponType.SWORD
@export var two_handed: bool = false

# Weapon stats
@export var base_damage: float = 10.0
@export var weight: float = 5.0
@export var durability: float = 100.0
@export var current_durability: float = 100.0

# Scaling with attributes (S, A, B, C, D, E)
enum ScalingRank {NONE, E, D, C, B, A, S}
@export var strength_scaling: ScalingRank = ScalingRank.D
@export var dexterity_scaling: ScalingRank = ScalingRank.D
@export var intelligence_scaling: ScalingRank = ScalingRank.NONE
@export var faith_scaling: ScalingRank = ScalingRank.NONE

# Weapon requirements
@export var required_strength: int = 10
@export var required_dexterity: int = 10
@export var required_intelligence: int = 0
@export var required_faith: int = 0

# Weapon properties
@export var stamina_cost_light: float = 15.0
@export var stamina_cost_heavy: float = 30.0
@export var attack_speed: float = 1.0  # Multiplier for animation speed
@export var range: float = 1.5  # Reach of the weapon

# Special effects
@export var has_special_attack: bool = false
@export var special_attack_description: String = ""
@export var special_attack_fp_cost: float = 0.0

# Weapon model
@export var model_path: String = ""

# Weapon moveset animations
@export var light_attack_anim: String = "light_attack"
@export var heavy_attack_anim: String = "heavy_attack"
@export var special_attack_anim: String = ""

# Get the scaling multiplier based on the rank
func get_scaling_multiplier(rank: ScalingRank) -> float:
    match rank:
        ScalingRank.NONE:
            return 0.0
        ScalingRank.E:
            return 0.3
        ScalingRank.D:
            return 0.5
        ScalingRank.C:
            return 0.75
        ScalingRank.B:
            return 1.0
        ScalingRank.A:
            return 1.25
        ScalingRank.S:
            return 1.5
        _:
            return 0.0

# Calculate total damage based on player stats
func calculate_damage(strength: int, dexterity: int, intelligence: int, faith: int) -> float:
    var total_damage = base_damage
    
    # Add scaling damage
    total_damage += base_damage * get_scaling_multiplier(strength_scaling) * (strength / 40.0)
    total_damage += base_damage * get_scaling_multiplier(dexterity_scaling) * (dexterity / 40.0)
    total_damage += base_damage * get_scaling_multiplier(intelligence_scaling) * (intelligence / 40.0)
    total_damage += base_damage * get_scaling_multiplier(faith_scaling) * (faith / 40.0)
    
    # Apply durability penalty if weapon is damaged
    var durability_factor = clamp(current_durability / durability, 0.5, 1.0)
    total_damage *= durability_factor
    
    return total_damage

# Check if player meets requirements to wield this weapon
func can_wield(strength: int, dexterity: int, intelligence: int, faith: int) -> bool:
    return strength >= required_strength and \
           dexterity >= required_dexterity and \
           intelligence >= required_intelligence and \
           faith >= required_faith

# Reduce durability when weapon is used
func use_weapon(is_heavy_attack: bool = false) -> void:
    var durability_loss = 1.0
    if is_heavy_attack:
        durability_loss = 2.0
    
    current_durability = max(0, current_durability - durability_loss)

# Repair weapon
func repair(amount: float = -1) -> void:
    if amount < 0:
        current_durability = durability
    else:
        current_durability = min(durability, current_durability + amount) 