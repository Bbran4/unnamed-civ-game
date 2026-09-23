class_name Weapon
extends Node3D

## Runtime weapon instance.
##
## WeaponData defines the static weapon design.
## Weapon stores runtime state such as cooldown and its owning ship.
##
## Projectile creation is intentionally deferred to the Projectile runtime
## task. For now, firing validates the weapon state, consumes ship energy and
## emits a fired signal that later systems can use to create a projectile.

signal fired(weapon: Weapon)

@export_category("Weapon Definition")
@export var weapon_data: WeaponData

@export_category("Runtime State")
var cooldown_remaining: float = 0.0
var ship: Ship


func _ready() -> void:
	_initialize_ship()


func _process(delta: float) -> void:
	if cooldown_remaining <= 0.0:
		cooldown_remaining = 0.0
		return

	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


## Assign the runtime ship that owns this weapon.
##
## The weapon does not assume a particular node hierarchy, which keeps it
## reusable for different ship scenes and weapon mount layouts.
func set_ship(new_ship: Ship) -> void:
	ship = new_ship


## Returns true when the weapon has valid data and can currently fire.
func can_fire() -> bool:
	if weapon_data == null:
		return false

	if cooldown_remaining > 0.0:
		return false

	if ship == null:
		return false

	return ship.current_energy >= maxf(weapon_data.energy_cost, 0.0)


## Attempt to fire the weapon.
##
## This does not create a projectile yet. It consumes the required ship energy,
## starts the weapon cooldown and emits a fired signal for the later projectile system.
func try_fire() -> bool:
	if not can_fire():
		return false

	var energy_cost: float = maxf(weapon_data.energy_cost, 0.0)
	ship.current_energy -= energy_cost

	var fire_rate: float = maxf(weapon_data.fire_rate, 0.0)

	if fire_rate > 0.0:
		cooldown_remaining = 1.0 / fire_rate
	else:
		cooldown_remaining = 0.0

	fired.emit(self)
	return true


## Returns the remaining cooldown in seconds.
func get_cooldown_remaining() -> float:
	return cooldown_remaining


## Returns the current cooldown as a normalized value from 0 to 1.
## 1 means a full cooldown remains, while 0 means ready to fire.
func get_cooldown_fraction() -> float:
	if weapon_data == null:
		return 0.0

	var fire_rate: float = maxf(weapon_data.fire_rate, 0.0)

	if fire_rate <= 0.0:
		return 0.0

	var cooldown_duration: float = 1.0 / fire_rate
	return clampf(cooldown_remaining / cooldown_duration, 0.0, 1.0)


func _initialize_ship() -> void:
	if ship != null:
		return

	var parent_ship: Ship = get_parent() as Ship

	if parent_ship != null:
		ship = parent_ship
