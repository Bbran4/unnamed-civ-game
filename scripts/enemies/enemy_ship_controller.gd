class_name EnemyShipController
extends ShipController

## Enemy ship controller.
##
## EnemyAIStateMachine makes the combat decisions.
## This controller translates those decisions into the same flight intent
## consumed by the reusable Ship flight model.

@export_category("Target")
@export var target_path: NodePath

var targeting_system: TargetingSystem
var ai_state_machine: EnemyAIStateMachine


func _ready() -> void:
	super._ready()

	if ship == null:
		return

	targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem

	if targeting_system == null:
		push_error("EnemyShipController requires a TargetingSystem.")
		return

	ai_state_machine = EnemyAIStateMachine.new()
	ai_state_machine.name = "AIStateMachine"
	add_child(ai_state_machine)
	ai_state_machine.setup(ship, targeting_system)

	if target_path != NodePath():
		var initial_target: Node3D = get_node_or_null(target_path) as Node3D
		targeting_system.set_target(initial_target)


func set_target(new_target: Node3D) -> void:
	if targeting_system != null:
		targeting_system.set_target(new_target)


func clear_target() -> void:
	if targeting_system != null:
		targeting_system.clear_target()


func get_ai_state() -> String:
	if ai_state_machine == null:
		return "IDLE"

	return ai_state_machine.get_state_name()


## Converts the current AI decision into reusable Ship flight intent.
func get_flight_intent(delta: float) -> Dictionary:
	if ai_state_machine == null:
		return super.get_flight_intent(delta)

	return ai_state_machine.get_flight_intent(delta)
