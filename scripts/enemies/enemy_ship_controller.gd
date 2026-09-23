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

var targeting_system: TargetingSystem


func _ready() -> void:
	super._ready()
	targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem

	if targeting_system != null and target_path != NodePath():
		var initial_target: Node3D = get_node_or_null(target_path) as Node3D
		targeting_system.set_target(initial_target)


func set_target(new_target: Node3D) -> void:
	if targeting_system != null:
		targeting_system.set_target(new_target)


func clear_target() -> void:
	if targeting_system != null:
		targeting_system.clear_target()


## Converts the current pursuit goal into reusable Ship flight intent.
##
## The controller does not move or rotate the ship directly.
## It only asks the Ship to:
## - turn toward the target
## - approach the preferred distance
## - brake when getting too close
func get_flight_intent(_delta: float) -> Dictionary:
	var intent := super.get_flight_intent(_delta)

	if ship == null or targeting_system == null:
		return intent

	var target: Node3D = targeting_system.get_target()

	if target == null:
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
