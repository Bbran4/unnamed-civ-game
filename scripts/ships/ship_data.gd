class_name ShipData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var faction_id: String = ""
@export var ship_class: String = "light_fighter"
@export var configuration_type: String = "standard"
@export var body: ShipBodyData
@export var wings: ShipWingsData
@export var tail: ShipTailData
@export var shield_capacity: int = 0
@export var shield_regeneration: float = 5.0
@export var modules: Array[ShipModuleData] = []
@export var weapons: Array[ShipWeaponData] = []

func get_weapon_mounts() -> int:
	if wings == null:
		return 0
	return mini(wings.weapon_mounts, 4)

func get_weapon(index: int) -> ShipWeaponData:
	if index < 0 or index >= weapons.size():
		return null
	return weapons[index]

func get_used_weapon_mounts() -> int:
	return mini(weapons.size(), get_weapon_mounts())

func has_weapon_capacity() -> bool:
	return weapons.size() < get_weapon_mounts()

func can_equip_weapon(weapon: ShipWeaponData) -> bool:
	if weapon == null:
		return false
	return has_weapon_capacity()

func equip_weapon(weapon: ShipWeaponData) -> bool:
	if not can_equip_weapon(weapon):
		return false
	weapons.append(weapon)
	return true

func set_weapon_at_mount(mount_index: int, weapon: ShipWeaponData) -> bool:
	if mount_index < 0 or mount_index >= get_weapon_mounts():
		return false
	if weapon == null:
		return false

	while weapons.size() <= mount_index:
		weapons.append(null)

	weapons[mount_index] = weapon
	return true

func remove_weapon_at_mount(mount_index: int) -> ShipWeaponData:
	if mount_index < 0 or mount_index >= weapons.size():
		return null

	var removed_weapon: ShipWeaponData = weapons[mount_index]
	weapons[mount_index] = null

	while not weapons.is_empty() and weapons[weapons.size() - 1] == null:
		weapons.pop_back()

	return removed_weapon

func get_module_slots() -> int:
	if body == null:
		return 0
	return body.module_slots

func get_used_module_slots() -> int:
	var module_slots: int = get_module_slots()
	return mini(modules.size(), module_slots)

func has_module_capacity() -> bool:
	return modules.size() < get_module_slots()

func get_total_hull_points() -> int:
	if body == null:
		return 0
	return body.hull_points

func get_total_armor() -> int:
	if body == null:
		return get_total_armor_bonus()
	return body.armor + get_total_armor_bonus()

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
	var total_speed: float = tail.max_speed
	for module: ShipModuleData in modules:
		if module != null:
			total_speed += module.speed_bonus
	return total_speed

func get_acceleration() -> float:
	if tail == null:
		return 0.0
	var total_acceleration: float = tail.acceleration
	for module: ShipModuleData in modules:
		if module != null:
			total_acceleration += module.acceleration_bonus
	return total_acceleration

func get_boost_multiplier() -> float:
	if tail == null:
		return 0.0
	return tail.boost_multiplier
