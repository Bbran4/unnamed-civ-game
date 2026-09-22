class_name ShipData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var faction_id: String = ""
@export var body: ShipBodyData
@export var wings: ShipWingsData
@export var tail: ShipTailData
@export var shield_capacity: int = 100
@export var shield_regeneration: float = 5.0
@export var module_slots: int = 0

func get_weapon_mounts() -> int:
	if wings == null:
		return 0
	return mini(wings.weapon_mounts, 4)

func get_max_speed() -> float:
	if tail == null:
		return 0.0
	return tail.max_speed
