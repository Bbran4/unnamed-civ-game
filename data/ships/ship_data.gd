class_name ShipData
extends Resource

## Static definition for a ship.
##
## ShipData contains the design inputs that describe a ship.
## Runtime state such as current hull, shields, velocity and installed
## equipment belongs to the Ship instance, not this resource.
##
## Flight characteristics are explicit gameplay values. Hull mass and
## dimensions are kept for ship identity, cargo/equipment systems and HUD
## presentation, but do not determine basic flight handling.

@export_category("Identity")
@export var id: StringName = &"ship"
@export var display_name: String = "Unnamed Ship"
@export_multiline var description: String = ""

@export_category("Physical")
## Approximate external dimensions in metres.
## X = width, Y = height, Z = length.
@export var dimensions: Vector3 = Vector3(10.0, 3.0, 6.0)

## Base hull mass before installed equipment and cargo.
## Mass is not currently used to calculate flight handling.
@export var hull_mass_kg: float = 10000.0

@export_category("Flight")
## Gameplay speed and acceleration values. These are deliberately direct so
## every ship can be tuned by feel without relying on physical derivations.
@export var max_speed_mps: float = 100.0
@export var acceleration_mps2: float = 50.0
@export var reverse_speed_mps: float = 50.0
@export var reverse_acceleration_mps2: float = 60.0
@export var strafe_speed_mps: float = 50.0
@export var strafe_acceleration_mps2: float = 80.0
@export var boost_speed_mps: float = 180.0
@export var boost_acceleration_mps2: float = 100.0
@export var flight_assist_acceleration_mps2: float = 120.0

## Turn rates are maximum angular velocities. Turn acceleration controls how
## quickly the ship reaches the requested turn rate.
@export var pitch_turn_rate_deg_s: float = 120.0
@export var yaw_turn_rate_deg_s: float = 120.0
@export var roll_turn_rate_deg_s: float = 150.0
@export var pitch_turn_acceleration_deg_s2: float = 360.0
@export var yaw_turn_acceleration_deg_s2: float = 360.0
@export var roll_turn_acceleration_deg_s2: float = 450.0

@export_category("Combat")
@export var hull_capacity: float = 100.0
@export var shield_capacity: float = 50.0
@export var energy_capacity: float = 100.0

## Seconds after taking damage before shield regeneration starts.
@export var shield_recharge_delay: float = 3.0

## Shield points restored per second after the recharge delay.
@export var shield_recharge_rate: float = 8.0

## Seconds after spending energy before energy regeneration starts.
@export var energy_recharge_delay: float = 1.5

## Energy points restored per second after the recharge delay.
@export var energy_recharge_rate: float = 20.0

@export_category("Slots")
@export var weapon_slots: int = 1
@export var missile_slots: int = 0
@export var utility_slots: int = 1

@export_category("Cargo")
@export var cargo_capacity: float = 10.0

@export_category("Economy")
@export var base_price: int = 10000
