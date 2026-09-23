class_name Ship
extends CharacterBody3D

## Reusable runtime ship.
##
## ShipData defines the ship's static design.
## Ship stores the runtime state of one actual vessel.
##
## Controllers will provide flight and combat intent to this node later.

@export_category("Ship Definition")
@export var ship_data: ShipData

@export_category("Runtime State")
var current_hull: float = 0.0
var current_shields: float = 0.0
var current_energy: float = 0.0

var throttle: float = 0.0
var boost_active: bool = false
var brake_active: bool = false

func _ready() -> void:
	_initialize_from_data()

func _initialize_from_data() -> void:
	if ship_data == null:
		push_warning("Ship has no ShipData assigned: %s" % name)
		return

	current_hull = ship_data.hull_capacity
	current_shields = ship_data.shield_capacity
	current_energy = ship_data.energy_capacity

func get_total_mass_kg() -> float:
	var total_mass := 0.0

	if ship_data != null:
		total_mass += ship_data.hull_mass_kg

	# Installed equipment mass will be added here when the equipment system
	# is introduced. Cargo mass will also contribute here later.
	return total_mass

func get_hull_fraction() -> float:
	if ship_data == null or ship_data.hull_capacity <= 0.0:
		return 0.0
	return current_hull / ship_data.hull_capacity

func get_shield_fraction() -> float:
	if ship_data == null or ship_data.shield_capacity <= 0.0:
		return 0.0
	return current_shields / ship_data.shield_capacity

func get_energy_fraction() -> float:
	if ship_data == null or ship_data.energy_capacity <= 0.0:
		return 0.0
	return current_energy / ship_data.energy_capacity

func is_destroyed() -> bool:
	return current_hull <= 0.0

func reset_runtime_state() -> void:
	if ship_data == null:
		return

	current_hull = ship_data.hull_capacity
	current_shields = ship_data.shield_capacity
	current_energy = ship_data.energy_capacity
	throttle = 0.0
	boost_active = false
	brake_active = false
	velocity = Vector3.ZERO
