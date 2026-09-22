class_name ShipWeaponData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var weapon_type: String = "energy"
@export var price: int = 0
@export var damage: float = 10.0
@export var fire_rate: float = 5.0
@export var projectile_speed: float = 1400.0
@export var range: float = 2800.0
@export var shield_damage_multiplier: float = 1.0
@export var hull_damage_multiplier: float = 1.0
@export var ammo_capacity: int = 0
@export var tracking: bool = false
@export var tracking_turn_speed: float = 3.0
