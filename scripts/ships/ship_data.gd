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
@export var modules: Array[ShipModuleData] = []

func get_weapon_mounts() -> int:
	if wings == null:
		return 0
	return mini(wings.weapon_mounts, 4)

func get_used_module_slots() -> int:
	return mini(modules.size(), module_slots)

func has_module_capacity() -> bool:
	return modules.size() < module_slots

func get_total_shield_capacity() -> int:
	var total_shield_capacity: int = shield_capacity
	for module: ShipModuleData in modules:
		if module != null:
			total_shield_capacity += module.shield_capacity_bonus
	return total_shield_capacity

func get_total_armor_bonus() -> int:
	var total_armor_bonus: int = 0
	for module: ShipModuleData in modules:
		if module != null:
			total_armor_bonus += module.armor_bonus
	return total_armor_bonus

func get_total_cargo_capacity() -> int:
	if wings == null:
		return 0
	var total_cargo_capacity: int = wings.cargo_capacity
	for module: ShipModuleData in modules:
		if module != null:
			total_cargo_capacity += module.cargo_capacity_bonus
	return total_cargo_capacity

func get_max_speed() -> float:
	if tail == null:
		return 0.0
	return tail.max_speed
