class_name ShieldSystem
extends RefCounted

## Shield damage helper.
##
## ShieldSystem owns the basic rule that shields absorb incoming damage before
## it can reach the hull. It does not own the Ship's shield state.
##
## Recharging, shield facing, regeneration delay and shield generators can be
## added later without changing projectile or weapon behaviour.

static func absorb_damage(
	current_shields: float,
	incoming_damage: float
) -> Dictionary:
	var shields: float = maxf(current_shields, 0.0)
	var damage: float = maxf(incoming_damage, 0.0)

	if damage <= 0.0:
		return {
			"remaining_shields": shields,
			"shield_damage": 0.0,
			"overflow_damage": 0.0
		}

	var shield_damage: float = minf(shields, damage)
	var overflow_damage: float = maxf(damage - shield_damage, 0.0)
	var remaining_shields: float = maxf(shields - shield_damage, 0.0)

	return {
		"remaining_shields": remaining_shields,
		"shield_damage": shield_damage,
		"overflow_damage": overflow_damage
	}
