class_name Weapon
extends Node3D

## Runtime weapon instance.
##
## WeaponData defines the static weapon design.
## Weapon stores runtime state such as cooldown and its owning ship.
##
## The weapon creates its configured Projectile runtime when fired. Damage
## handling remains separate and belongs to the DamageSystem task.

signal fired(weapon: Weapon)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/projectile.tscn")

@export_category("Weapon Definition")
@export var weapon_data: WeaponData

@export_category("Runtime State")
var cooldown_remaining: float = 0.0
var ship: Ship

@onready var muzzle: Marker3D = $Muzzle


func _ready() -> void:
	_initialize_ship()


func _process(delta: float) -> void:
	if cooldown_remaining <= 0.0:
		cooldown_remaining = 0.0
		return

	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


## Assign the runtime ship that owns this weapon.
func set_ship(new_ship: Ship) -> void:
	ship = new_ship


## Returns true when the weapon has valid data and can currently fire.
func can_fire() -> bool:
	if weapon_data == null:
		return false

	if weapon_data.projectile_data == null:
		return false

	if cooldown_remaining > 0.0:
		return false

	if ship == null:
		return false

	return ship.current_energy >= maxf(weapon_data.energy_cost, 0.0)


## Attempt to fire the weapon.
##
## A successful fire consumes ship energy, starts the weapon cooldown and
## launches one Projectile using the weapon's projectile definition.
func try_fire(fire_direction: Vector3 = Vector3.ZERO) -> bool:
	if not can_fire():
		return false

	var projectile: Projectile = _spawn_projectile(fire_direction)

	if projectile == null:
		return false

	var energy_cost: float = maxf(weapon_data.energy_cost, 0.0)

	if not ship.consume_energy(energy_cost):
		projectile.queue_free()
		return false

	var fire_rate: float = maxf(weapon_data.fire_rate, 0.0)

	if fire_rate > 0.0:
		cooldown_remaining = 1.0 / fire_rate
	else:
		cooldown_remaining = 0.0

	fired.emit(self)
	return true


func get_cooldown_remaining() -> float:
	return cooldown_remaining


## Returns the current cooldown as a normalized value from 0 to 1.
func get_cooldown_fraction() -> float:
	if weapon_data == null:
		return 0.0

	var fire_rate: float = maxf(weapon_data.fire_rate, 0.0)

	if fire_rate <= 0.0:
		return 0.0

	var cooldown_duration: float = 1.0 / fire_rate
	return clampf(cooldown_remaining / cooldown_duration, 0.0, 1.0)


func _spawn_projectile(fire_direction: Vector3 = Vector3.ZERO) -> Projectile:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile

	if projectile == null:
		push_error("Projectile scene must instantiate Projectile.")
		return null

	projectile.set_projectile_data(weapon_data.projectile_data)

	var projectile_parent: Node = get_tree().current_scene

	if projectile_parent == null:
		projectile_parent = ship.get_parent()

	if projectile_parent == null:
		projectile.queue_free()
		push_error("Weapon could not find a parent for the projectile.")
		return null

	projectile_parent.add_child(projectile)

	var direction: Vector3 = fire_direction.normalized()

	if direction.length_squared() <= 0.0001:
		direction = -muzzle.global_transform.basis.z

	projectile.launch(
		muzzle.global_position,
		direction,
		ship
	)

	return projectile


func _initialize_ship() -> void:
	if ship != null:
		return

	var parent_ship: Ship = get_parent() as Ship

	if parent_ship != null:
		ship = parent_ship
