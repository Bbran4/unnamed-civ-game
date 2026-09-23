class_name TargetingSystem
extends Node

## Reusable runtime targeting system.
##
## TargetingSystem owns the current target for one ship and provides safe
## helpers for acquiring and validating targets. It does not decide when the
## player or AI should lock a target. That behaviour belongs to the higher-level
## target-lock and AI systems.
##
## Ships are registered in the "ships" group so the system can find nearby
## runtime ships without depending on a specific scene hierarchy.

signal target_changed(previous_target: Node3D, new_target: Node3D)
signal target_lost(previous_target: Node3D)

var ship: Ship
var current_target: Node3D


func _ready() -> void:
	ship = get_parent() as Ship

	if ship == null:
		push_error("TargetingSystem must be a child of a Ship.")
		return

	ship.add_to_group("ships")


func _process(_delta: float) -> void:
	_validate_current_target()


## Set a target explicitly.
##
## Any Node3D can be assigned, but higher-level code should normally target
## Ships or other targetable gameplay objects.
func set_target(new_target: Node3D) -> bool:
	if new_target == null or not is_instance_valid(new_target):
		clear_target()
		return false

	if ship != null and new_target == ship:
		return false

	var previous_target: Node3D = current_target
	current_target = new_target

	if previous_target != current_target:
		target_changed.emit(previous_target, current_target)

	return true


## Clear the current target.
func clear_target() -> void:
	if current_target == null:
		return

	var previous_target: Node3D = current_target
	current_target = null
	target_lost.emit(previous_target)


## Returns the current target if it is still valid.
func get_target() -> Node3D:
	_validate_current_target()
	return current_target


func has_target() -> bool:
	return get_target() != null


## Find the nearest valid Ship within max_distance.
##
## Destroyed ships are ignored.
func acquire_nearest_target(max_distance: float = INF) -> Ship:
	if ship == null:
		return null

	var nearest_target: Ship
	var nearest_distance_squared: float = max_distance * max_distance

	for candidate_node: Node in get_tree().get_nodes_in_group("ships"):
		var candidate: Ship = candidate_node as Ship

		if candidate == null or candidate == ship:
			continue

		if candidate.is_destroyed():
			continue

		var distance_squared: float = ship.global_position.distance_squared_to(
			candidate.global_position
		)

		if distance_squared > nearest_distance_squared:
			continue

		nearest_distance_squared = distance_squared
		nearest_target = candidate

	if nearest_target != null:
		set_target(nearest_target)

	return nearest_target


## Returns the distance to the current target in metres.
func get_target_distance() -> float:
	var target: Node3D = get_target()

	if target == null or ship == null:
		return INF

	return ship.global_position.distance_to(target.global_position)


## Returns a normalized direction from the owning ship to its current target.
func get_target_direction() -> Vector3:
	var target: Node3D = get_target()

	if target == null or ship == null:
		return Vector3.ZERO

	var offset: Vector3 = target.global_position - ship.global_position

	if offset.length_squared() <= 0.0001:
		return Vector3.ZERO

	return offset.normalized()


## Returns the current target direction in the owning ship's local space.
func get_target_local_direction() -> Vector3:
	var direction: Vector3 = get_target_direction()

	if direction == Vector3.ZERO or ship == null:
		return Vector3.ZERO

	return ship.global_transform.basis.inverse() * direction


func is_target_in_range(range_m: float) -> bool:
	if range_m < 0.0:
		return false

	return get_target_distance() <= range_m


func _validate_current_target() -> void:
	if current_target == null:
		return

	if not is_instance_valid(current_target):
		var previous_target: Node3D = current_target
		current_target = null
		target_lost.emit(previous_target)
		return

	var target_ship: Ship = current_target as Ship

	if target_ship != null and target_ship.is_destroyed():
		var previous_ship: Node3D = current_target
		current_target = null
		target_lost.emit(previous_ship)
