class_name WeaponData
extends EquipmentData

## Static definition for an installable weapon.
##
## WeaponData inherits EquipmentData so weapon mass automatically contributes
## to the runtime Ship's total mass.
##
## This resource contains weapon design inputs only. Runtime state such as
## cooldowns, ammunition, firing state and current target belongs to Weapon.

enum WeaponType {
	ENERGY,
	PROJECTILE,
	MISSILE
}

@export_category("Weapon")
@export var weapon_type: WeaponType = WeaponType.ENERGY

## Damage applied by one successful hit.
@export var damage: float = 10.0

## Maximum effective weapon range in metres.
@export var range_m: float = 1000.0

## Shots fired per second.
@export var fire_rate: float = 2.0

## Ship energy consumed by each shot.
@export var energy_cost: float = 5.0

## Projectile travel speed in metres per second.
## Used by projectile and missile weapons; energy weapons may ignore it.
@export var projectile_speed_mps: float = 500.0

## Projectile definition used by projectile-based weapons.
@export var projectile_data: ProjectileData
