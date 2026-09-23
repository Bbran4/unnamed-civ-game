class_name EnemyAIStateMachine
extends Node

## Small state machine for enemy combat decisions.
##
## The state machine decides what the enemy wants to do. EnemyShipController
## translates that decision into the shared Ship flight-intent format.
##
## States are deliberately simple for the first dogfight:
## IDLE -> PURSUIT -> ATTACK
##                 -> EVADE
##                 -> FLEE
##
## This is not a behaviour tree or a general-purpose AI framework. More
## sophisticated behaviours can be added when the gameplay actually needs them.

enum State {
	IDLE,
	PURSUIT,
	ATTACK,
	EVADE,
	FLEE
}

signal state_changed(previous_state: int, new_state: int)

@export_category("Detection")
@export var detection_range: float = 1500.0

@export_category("Combat")
@export var attack_range: float = 120.0
@export var preferred_attack_distance: float = 75.0
@export var attack_distance_tolerance: float = 15.0
@export var orbit_direction: float = 1.0

@export_category("Survival")
@export_range(0.0, 1.0) var evade_shield_fraction: float = 0.35
@export_range(0.0, 1.0) var flee_hull_fraction: float = 0.25
@export var evade_duration: float = 2.5
@export var flee_disengage_distance: float = 350.0

@export_category("Steering")
@export var steering_deadzone: float = 0.05


var ship: Ship
var targeting_system: TargetingSystem
var current_state: State = State.IDLE
var evade_timer: float = 0.0

func setup(new_ship: Ship, new_targeting_system: TargetingSystem) -> void:
	ship = new_ship
	targeting_system = new_targeting_system

if ship != null:
		ship.shields_hit.connect(_on_shields_hit)
		ship.hull_hit.connect(_on_hull_hit)
		ship.destroyed.connect(_on_ship_destroyed)


func get_state() -> int:
	return current_state


func get_state_name() -> String:
	return State.keys()[current_state]


func get_flight_intent(delta: float) -> Dictionary:
	var intent: Dictionary = _get_neutral_intent()

	if ship == null or targeting_system == null or ship.is_destroyed():
		transition_to(State.IDLE)
		return intent

	evade_timer = maxf(evade_timer - delta, 0.0)
	_update_state()

	match current_state:
		State.IDLE:
			return _build_idle_intent(intent)

		State.PURSUIT:
			return _build_pursuit_intent(intent)

		State.ATTACK:
			return _build_attack_intent(intent)

		State.EVADE:
			return _build_evade_intent(intent)

		State.FLEE:
			return _build_flee_intent(intent)

	return intent


func transition_to(new_state: int) -> void:
	if current_state == new_state:
		return

	var previous_state: State = current_state
	current_state = new_state
	state_changed.emit(previous_state, new_state)


func _update_state() -> void:
	var target: Node3D = targeting_system.get_target()

	if current_state == State.FLEE:
		if target == null:
			transition_to(State.IDLE)
			return

		if targeting_system.get_target_distance() >= flee_disengage_distance:
			transition_to(State.IDLE)

		return

	if ship.get_hull_fraction() <= flee_hull_fraction:
		transition_to(State.FLEE)
		return

	if evade_timer > 0.0:
		transition_to(State.EVADE)
		return

	if target == null:
		var acquired_target: Ship = targeting_system.acquire_nearest_target(detection_range)

		if acquired_target == null:
			transition_to(State.IDLE)
		else:
			transition_to(State.PURSUIT)

		return

	var distance: float = targeting_system.get_target_distance()

	if distance > attack_range:
		transition_to(State.PURSUIT)
	else:
		transition_to(State.ATTACK)


func _build_idle_intent(intent: Dictionary) -> Dictionary:
	# A future patrol behaviour can replace this with waypoint movement.
	return intent


func _build_pursuit_intent(intent: Dictionary) -> Dictionary:
	var target_direction: Vector3 = targeting_system.get_target_direction()
	_apply_steering_toward(intent, target_direction)

	var distance: float = targeting_system.get_target_distance()

	if distance > preferred_attack_distance:
		intent["throttle"] = 1.0
	else:
		intent["brake"] = true

	if distance > attack_range * 2.0:
		intent["boost"] = true

	return intent


func _build_attack_intent(intent: Dictionary) -> Dictionary:
	var target_direction: Vector3 = targeting_system.get_target_direction()
	_apply_steering_toward(intent, target_direction)

	var local_direction: Vector3 = targeting_system.get_target_local_direction()
	var distance: float = targeting_system.get_target_distance()

	if distance > preferred_attack_distance + attack_distance_tolerance:
		intent["throttle"] = 1.0
	elif distance < preferred_attack_distance - attack_distance_tolerance:
		intent["brake"] = true
	else:
		intent["strafe"] = clampf(orbit_direction, -1.0, 1.0)

	if abs(local_direction.x) < 0.25 and abs(local_direction.y) < 0.25:
		intent["strafe"] = clampf(orbit_direction, -1.0, 1.0)

	# The weapon system decides whether a weapon can actually fire.
	# This lets the same AI work before and after enemy weapons are installed.
	intent["fire"] = true

	return intent


func _build_evade_intent(intent: Dictionary) -> Dictionary:
	var target_direction: Vector3 = targeting_system.get_target_direction()

	if target_direction == Vector3.ZERO:
		intent["boost"] = true
		intent["throttle"] = 1.0
		intent["strafe"] = clampf(orbit_direction, -1.0, 1.0)
		return intent

	# Break away from the incoming target direction while maintaining enough
	# forward thrust to keep the ship moving through the engagement.
	var local_escape_direction: Vector3 = (
		ship.global_transform.basis.inverse() * -target_direction
	)

	_apply_local_direction_steering(intent, local_escape_direction)
	intent["throttle"] = 1.0
	intent["boost"] = true
	intent["strafe"] = clampf(orbit_direction, -1.0, 1.0)

	return intent


func _build_flee_intent(intent: Dictionary) -> Dictionary:
	var target_direction: Vector3 = targeting_system.get_target_direction()

	if target_direction == Vector3.ZERO:
		intent["throttle"] = 1.0
		intent["boost"] = true
		return intent

	var local_escape_direction: Vector3 = (
		ship.global_transform.basis.inverse() * -target_direction
	)

	_apply_local_direction_steering(intent, local_escape_direction)
	intent["throttle"] = 1.0
	intent["boost"] = true

	return intent


func _apply_steering_toward(intent: Dictionary, world_direction: Vector3) -> void:
	if world_direction == Vector3.ZERO:
		return

	var local_direction: Vector3 = (
		ship.global_transform.basis.inverse() * world_direction
	)

	_apply_local_direction_steering(intent, local_direction)


func _apply_local_direction_steering(
	intent: Dictionary,
	local_direction: Vector3
) -> void:
	if abs(local_direction.x) > steering_deadzone:
		intent["yaw"] = clampf(-local_direction.x, -1.0, 1.0)

	if abs(local_direction.y) > steering_deadzone:
		intent["pitch"] = clampf(local_direction.y, -1.0, 1.0)


func _get_neutral_intent() -> Dictionary:
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


func _on_shields_hit(
	_amount: float,
	_source: Node,
	_remaining_shields: float
) -> void:
	if ship == null or ship.is_destroyed():
		return

if ship.get_hull_fraction() > flee_hull_fraction:
		evade_timer = evade_duration


func _on_hull_hit(
	_amount: float,
	_source: Node,
	_remaining_hull: float
) -> void:
	if ship == null or ship.is_destroyed():
		return

	if ship.get_hull_fraction() <= flee_hull_fraction:
		transition_to(State.FLEE)
	else:
		evade_timer = evade_duration


func _on_ship_destroyed(_source: Node) -> void:
	evade_timer = 0.0
	transition_to(State.IDLE)
