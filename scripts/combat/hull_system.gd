class_name HullSystem
extends RefCounted

## Hull damage helper.
##
## HullSystem owns the basic rule for applying damage to a ship's hull.
## It does not own the Ship's hull state.
##
## More advanced hull behaviour, such as subsystem damage, critical states,
## armour types and destruction sequencing, can be added later without
## changing how the DamageSystem or Projectile delivers damage.

static func apply_damage(
	current_hull: float,
	incoming_damage: float,
	hull_capacity: float
) -> Dictionary:
	var hull: float = maxf(current_hull, 0.0)
	var damage: float = maxf(incoming_damage, 0.0)
	var maximum_hull: float = maxf(hull_capacity, 0.0)

	if damage <= 0.0 or maximum_hull <= 0.0:
		return {
			"remaining_hull": clampf(hull, 0.0, maximum_hull),
			"hull_damage": 0.0,
			"destroyed": hull <= 0.0
		}

	var hull_damage: float = minf(hull, damage)
	var remaining_hull: float = clampf(hull - damage, 0.0, maximum_hull)

	return {
		"remaining_hull": remaining_hull,
		"hull_damage": hull_damage,
		"destroyed": remaining_hull <= 0.0
	}
