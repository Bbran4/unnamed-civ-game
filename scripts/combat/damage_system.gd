class_name DamageSystem
extends RefCounted

## Central damage dispatcher.
##
## DamageSystem validates damage requests and forwards them to targets that
## expose a receive_damage() method. The projectile, weapon and other combat
## systems do not directly manipulate a target's internal health state.
##
## This keeps damage delivery separate from shields, hull behaviour and
## destruction rules, which can be expanded in their dedicated systems later.

static func apply_damage(source: Node, target: Node, amount: float) -> bool:
	if target == null or not is_instance_valid(target):
		return false

	if source != null and target == source:
		return false

	var damage: float = maxf(amount, 0.0)

	if damage <= 0.0:
		return false

	if not target.has_method("receive_damage"):
		return false

	target.receive_damage(damage, source)
	return true
