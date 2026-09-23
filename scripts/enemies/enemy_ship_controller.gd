class_name EnemyShipController
extends ShipController

## Basic enemy flight controller.
##
## This is deliberately not the enemy AI state machine.
## The controller only converts a simple pursuit decision into the same flight
## intent used by the player controller.
##
## Later, an enemy AI state machine can own decisions such as patrol, pursue,
## attack, evade and flee, then feed those decisions into this controller.

@export_category("Target")
@export var target_path: NodePath

@export_category("Pursuit")
## Preferred distance to maintain from the target in metres.
@export var desired_distance: float = 75.0

## Distance at which the controller starts braking to avoid overshooting.
@export var braking_distance: float = 35.0

## Small local-direction deadzone to prevent constant micro-corrections.
@export var steering_deadzone: float = 0.05

var target: Node3D


func _ready() -> void:
	super._ready()

	if target_path != NodePath():
		target = get_node_or_null(target_path) as Node3D


func set_target(new_target: Node3D) -> void:
	target = new_target


func clear_target() -> void:
	target = null


## Converts the current pursuit goal into reusable Ship flight intent.
##
## The controller does not move or rotate the ship directly.
## It only asks the Ship to:
## - turn toward the target
## - approach the preferred distance
## - brake when getting too close
func get_flight_intent(_delta: float) -> Dictionary:
	var intent := super.get_flight_intent(_delta)

	if ship == null or target == null or not is_instance_valid(target):
		return intent

	var to_target: Vector3 = target.global_position - ship.global_position
	var distance: float = to_target.length()

	if distance <= 0.01:
		return intent

	var target_direction: Vector3 = to_target.normalized()
	var local_direction: Vector3 = (
		ship.global_transform.basis.inverse() * target_direction
	)

	if abs(local_direction.x) > steering_deadzone:
		intent["yaw"] = clampf(-local_direction.x, -1.0, 1.0)

	if abs(local_direction.y) > steering_deadzone:
		intent["pitch"] = clampf(local_direction.y, -1.0, 1.0)

	if distance > desired_distance:
		intent["throttle"] = 1.0
	elif distance < desired_distance:
		intent["throttle"] = -1.0

	if distance < braking_distance:
		intent["brake"] = true

	return intent
