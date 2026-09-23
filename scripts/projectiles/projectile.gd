class_name Projectile
extends CharacterBody3D

## Runtime projectile instance.
##
## ProjectileData defines the static projectile design.
## Projectile stores runtime state such as velocity, lifetime and ownership.
##
## The projectile detects collisions and emits a hit signal, but it does not
## apply damage yet. Damage handling belongs to the DamageSystem task.

signal hit(projectile: Projectile, target: Node3D)
signal expired(projectile: Projectile)

@export_category("Projectile Definition")
@export var projectile_data: ProjectileData

@export_category("Runtime State")
var owner_ship: Ship
var target: Node3D
var remaining_lifetime: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_initialize_from_data()


func _physics_process(delta: float) -> void:
	if projectile_data == null:
		queue_free()
		return

	remaining_lifetime -= delta

	if remaining_lifetime <= 0.0:
		expired.emit(self)
		queue_free()
		return

	if projectile_data.homing and target != null and is_instance_valid(target):
		_apply_homing(delta)

	var collision: KinematicCollision3D = move_and_collide(velocity * delta)

	if collision == null:
		return

	var collider: Object = collision.get_collider()

	if collider == owner_ship:
		return

	var target_node: Node3D = collider as Node3D

	if target_node == null:
		return

	hit.emit(self, target_node)
	queue_free()


## Prepare the projectile for launch.
##
## Direction is normalized internally and the projectile starts at
## start_position. The owner is ignored when the projectile first collides
## with its launching ship.
func launch(
	start_position: Vector3,
	direction: Vector3,
	new_owner_ship: Ship = null,
	new_target: Node3D = null
) -> void:
	global_position = start_position
	owner_ship = new_owner_ship
	target = new_target

	var launch_direction: Vector3 = direction.normalized()

	if launch_direction.length_squared() <= 0.0001:
		launch_direction = -global_transform.basis.z

	if projectile_data != null:
		velocity = launch_direction * projectile_data.speed_mps
		remaining_lifetime = maxf(projectile_data.lifetime, 0.0)
	else:
		velocity = launch_direction
		remaining_lifetime = 0.0


## Assign projectile data and refresh its runtime properties.
func set_projectile_data(new_data: ProjectileData) -> void:
	projectile_data = new_data
	_initialize_from_data()


## Returns the damage this projectile is configured to deliver.
func get_damage() -> float:
	if projectile_data == null:
		return 0.0

	return maxf(projectile_data.damage, 0.0)


func _initialize_from_data() -> void:
	if projectile_data == null:
		return

	remaining_lifetime = maxf(projectile_data.lifetime, 0.0)

	var collision_shape: CollisionShape3D = $CollisionShape3D
	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = maxf(projectile_data.radius, 0.01)
	collision_shape.shape = sphere_shape


func _apply_homing(delta: float) -> void:
	var to_target: Vector3 = target.global_position - global_position

	if to_target.length_squared() <= 0.0001:
		return

	var current_direction: Vector3 = velocity.normalized()

	if current_direction.length_squared() <= 0.0001:
		return

	var target_direction: Vector3 = to_target.normalized()
	var turn_fraction: float = clampf(
		maxf(projectile_data.turn_rate_rad_s, 0.0) * delta,
		0.0,
		1.0
	)

	var new_direction: Vector3 = current_direction.slerp(
		target_direction,
		turn_fraction
	).normalized()

	velocity = new_direction * projectile_data.speed_mps
