class_name ShipData
extends Resource

## Static definition for a ship.
##
## ShipData contains the design inputs that describe a ship.
## Runtime state such as current hull, shields, velocity and installed
## equipment belongs to the Ship instance, not this resource.
##
## Flight characteristics such as acceleration, braking and rotation are
## derived later by the runtime Ship from these values.

@export_category("Identity")
@export var id: StringName = &"ship"
@export var display_name: String = "Unnamed Ship"
@export_multiline var description: String = ""

@export_category("Physical")
## Approximate external dimensions in metres.
## X = width, Y = height, Z = length.
@export var dimensions: Vector3 = Vector3(10.0, 3.0, 6.0)

## Base hull mass before installed equipment and cargo.
@export var hull_mass_kg: float = 10000.0

@export_category("Propulsion")
## Main forward engine thrust in newtons.
@export var main_engine_thrust_n: float = 300000.0

## Reverse / braking thrust in newtons.
@export var reverse_engine_thrust_n: float = 150000.0

## Total available maneuvering / RCS thrust in newtons.
## Used later to derive strafe and rotational behaviour.
@export var maneuvering_thrust_n: float = 75000.0

## Additional engine thrust available while boosting.
@export var boost_thrust_n: float = 450000.0

@export_category("Combat")
@export var hull_capacity: float = 100.0
@export var shield_capacity: float = 50.0
@export var energy_capacity: float = 100.0

@export_category("Slots")
@export var weapon_slots: int = 1
@export var missile_slots: int = 0
@export var utility_slots: int = 1

@export_category("Cargo")
@export var cargo_capacity: float = 10.0

@export_category("Economy")
@export var base_price: int = 10000
