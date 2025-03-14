extends Area3D
class_name EnemyProjectile

"""
EnemyProjectile: Projectile fired by enemies for ranged attacks.
"""

# Projectile properties
@export var speed: float = 10.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0
@export var gravity_affected: bool = false
@export var homing: bool = false
@export var homing_strength: float = 0.1
@export var homing_duration: float = 2.0

# Runtime variables
var direction: Vector3 = Vector3.FORWARD
var velocity: Vector3 = Vector3.ZERO
var source = null
var target = null
var homing_timer: float = 0.0

# Node references
var collision_shape: CollisionShape3D
var mesh_instance: MeshInstance3D
var particles: GPUParticles3D

# Called when the node enters the scene tree for the first time
func _ready():
	# Get node references
	collision_shape = $CollisionShape3D
	mesh_instance = $MeshInstance3D
	particles = $Particles
	
	# Connect signals
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	
	# Set initial velocity
	velocity = direction * speed
	
	# Start lifetime timer
	if lifetime > 0:
		var timer = get_tree().create_timer(lifetime)
		timer.connect("timeout", Callable(self, "_on_lifetime_expired"))
	
	# Initialize homing timer
	if homing:
		homing_timer = homing_duration
		
		# Find player as target if not set
		if not target:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				target = players[0]

# Initialize the projectile
func initialize(dir: Vector3, dmg: float, src = null):
	direction = dir.normalized()
	damage = dmg
	source = src
	
	# Set initial velocity
	velocity = direction * speed

# Called every physics frame
func _physics_process(delta):
	# Update homing behavior
	if homing and homing_timer > 0 and target and is_instance_valid(target):
		homing_timer -= delta
		
		# Calculate direction to target
		var to_target = (target.global_position - global_position).normalized()
		
		# Gradually adjust direction towards target
		direction = direction.lerp(to_target, homing_strength * delta).normalized()
		velocity = direction * speed
	
	# Apply gravity if affected
	if gravity_affected:
		velocity.y -= 9.8 * delta
	
	# Update position
	global_position += velocity * delta
	
	# Rotate to face direction of travel
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)

# Handle collision with bodies
func _on_body_entered(body):
	if body.is_in_group("player"):
		_hit_player(body)
	elif body != source:
		_impact()

# Handle collision with areas
func _on_area_entered(area):
	if area.get_parent() and area.get_parent().is_in_group("player") and area.name == "HurtBox":
		_hit_player(area.get_parent())

# Hit player and apply damage
func _hit_player(player):
	if player.has_method("take_damage"):
		player.take_damage(damage, source)
	
	_impact()

# Handle impact
func _impact():
	# Disable collision
	if collision_shape:
		collision_shape.disabled = true
	
	# Stop movement
	velocity = Vector3.ZERO
	
	# Hide mesh
	if mesh_instance:
		mesh_instance.visible = false
	
	# Play impact particles
	if particles:
		particles.emitting = true
		await get_tree().create_timer(particles.lifetime).timeout
	
	# Remove projectile
	queue_free()

# Handle lifetime expiration
func _on_lifetime_expired():
	queue_free() 