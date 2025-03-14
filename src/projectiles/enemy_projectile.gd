extends Area3D
class_name EnemyProjectile

"""
EnemyProjectile: Projectile fired by enemies for ranged attacks.
"""

# Projectile properties
@export var speed: float = 15.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0
@export var gravity_affected: bool = false
@export var homing: bool = false
@export var homing_strength: float = 0.1
@export var homing_duration: float = 1.0

# Runtime variables
var direction: Vector3 = Vector3.FORWARD
var velocity: Vector3 = Vector3.ZERO
var source = null
var target = null
var homing_timer: float = 0.0

# Node references
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var particles: GPUParticles3D = $Particles

func _ready() -> void:
	"""Initialize the projectile."""
	# Connect signals
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	
	# Set initial velocity
	velocity = direction * speed
	
	# Look in the direction of movement
	look_at(global_position + direction, Vector3.UP)
	
	# Start lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.connect("timeout", Callable(self, "_on_lifetime_expired"))
	
	# If homing, find player target
	if homing:
		target = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null

func _physics_process(delta: float) -> void:
	"""Update projectile position and behavior."""
	# Apply gravity if affected
	if gravity_affected:
		velocity.y -= 9.8 * delta
	
	# Apply homing behavior
	if homing and target and is_instance_valid(target) and homing_timer < homing_duration:
		var target_direction = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, homing_strength * delta).normalized()
		velocity = direction * speed
		look_at(global_position + direction, Vector3.UP)
		homing_timer += delta
	
	# Update position
	global_position += velocity * delta

func _on_body_entered(body: Node3D) -> void:
	"""Handle collision with bodies."""
	if body is PlayerCharacter:
		_hit_player(body)
	else:
		# Hit environment
		_impact()

func _on_area_entered(area: Area3D) -> void:
	"""Handle collision with areas."""
	if area.is_in_group("player_hurt_box"):
		var player = area.get_parent()
		if player is PlayerCharacter:
			_hit_player(player)

func _hit_player(player: PlayerCharacter) -> void:
	"""Handle hitting the player."""
	if player.has_method("take_damage"):
		player.take_damage(damage, source)
	
	_impact()

func _impact() -> void:
	"""Handle projectile impact."""
	# Disable collision
	collision_shape.disabled = true
	
	# Stop movement
	velocity = Vector3.ZERO
	
	# Hide mesh
	mesh_instance.visible = false
	
	# Play impact particles
	if particles:
		particles.emitting = true
		await get_tree().create_timer(particles.lifetime).timeout
	
	# Remove projectile
	queue_free()

func _on_lifetime_expired() -> void:
	"""Handle projectile lifetime expiration."""
	queue_free() 