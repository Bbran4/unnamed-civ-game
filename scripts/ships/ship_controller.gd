class_name ShipController
extends Node

## Base controller for a Ship.
##
## A controller decides what the ship should do.
## The Ship is responsible for applying that intent to its flight model.
##
## PlayerShipController and EnemyShipController will inherit from this class.

var ship: Ship

func _ready() -> void:
	ship = get_parent() as Ship

	if ship == null:
		push_error("ShipController must be a child of a Ship.")

## Returns the control intent for the current physics frame.
##
## Values:
## pitch       -1.0 to 1.0
## yaw         -1.0 to 1.0
## roll        -1.0 to 1.0
## strafe      -1.0 to 1.0
## throttle    -1.0 to 1.0
## brake       true/false
## boost       true/false
## fire             true/false
## fire_direction   optional world-space firing direction
##
## The base controller provides neutral input. Specific controllers override
## this method to provide player input or AI decisions.
func get_flight_intent(_delta: float) -> Dictionary:
	return {
		"pitch": 0.0,
		"yaw": 0.0,
		"roll": 0.0,
		"strafe": 0.0,
		"throttle": 0.0,
		"brake": false,
		"boost": false,
		"fire": false
	}
