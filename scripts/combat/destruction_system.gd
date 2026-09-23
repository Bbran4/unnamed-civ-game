class_name DestructionSystem
extends RefCounted

## Ship destruction handler.
##
## DestructionSystem applies the runtime transition from an active ship to a
## destroyed wreck. The wreck remains in the scene so later systems can react
## to it with salvage, boarding, mission consequences or visual effects.
##
## The system does not decide rewards, explosion effects or cleanup. Those are
## separate concerns that can listen for the Ship's destroyed signal.

static func destroy(ship: Ship, source: Node = null) -> bool:
	if ship == null or not is_instance_valid(ship):
		return false

	if ship.destroyed_state:
		return false

	ship.destroyed_state = true
	ship.velocity = Vector3.ZERO
	ship.angular_velocity = Vector3.ZERO
	ship.throttle = 0.0
	ship.boost_active = false
	ship.brake_active = false
	ship.controller = null

	for weapon: Weapon in ship.weapons:
		if weapon != null:
			weapon.queue_free()

	for child: Node in ship.get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)

	ship.destroyed.emit(source)
	return true
