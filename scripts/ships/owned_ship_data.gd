class_name OwnedShipData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var ship_template: ShipData
@export var installed_weapons: Array[ShipWeaponData] = []
@export var installed_modules: Array[ShipModuleData] = []
@export var cargo: Dictionary = {}
@export var current_hull: float = 0.0
@export var current_shield: float = 0.0

static func create_from_template(template: ShipData) -> OwnedShipData:
	var owned_ship: OwnedShipData = OwnedShipData.new()
	owned_ship.initialize_from_template(template)
	return owned_ship

func initialize_from_template(template: ShipData) -> void:
	ship_template = template
	installed_weapons.clear()
	installed_modules.clear()
	cargo.clear()
	current_hull = 0.0
	current_shield = 0.0

	if ship_template == null:
		id = ""
		display_name = ""
		return

	id = ship_template.id
	display_name = ship_template.display_name

	for weapon: ShipWeaponData in ship_template.weapons:
		if weapon != null:
			installed_weapons.append(weapon)

	for module: ShipModuleData in ship_template.modules:
		if module != null:
			installed_modules.append(module)

	current_hull = float(get_total_hull_points())
	current_shield = float(get_total_shield_capacity())

func get_weapon_mounts() -> int:
	if ship_template == null:
		return 0
	if ship_template.wings == null:
		return 0
	return mini(ship_template.wings.weapon_mounts, 4)

func get_weapon(index: int) -> ShipWeaponData:
	if index < 0 or index >= installed_weapons.size():
		return null
	return installed_weapons[index]

func get_used_weapon_mounts() -> int:
	return mini(installed_weapons.size(), get_weapon_mounts())

func has_weapon_capacity() -> bool:
	return installed_weapons.size() < get_weapon_mounts()

func can_equip_weapon(weapon: ShipWeaponData) -> bool:
	if weapon == null:
		return false
	return has_weapon_capacity()

func equip_weapon(weapon: ShipWeaponData) -> bool:
	if not can_equip_weapon(weapon):
		return false
	installed_weapons.append(weapon)
	return true

func set_weapon_at_mount(mount_index: int, weapon: ShipWeaponData) -> bool:
	if mount_index < 0 or mount_index >= get_weapon_mounts():
		return false
	if weapon == null:
		return false

	while installed_weapons.size() <= mount_index:
		installed_weapons.append(null)

	installed_weapons[mount_index] = weapon
	return true

func remove_weapon_at_mount(mount_index: int) -> ShipWeaponData:
	if mount_index < 0 or mount_index >= installed_weapons.size():
		return null

	var removed_weapon: ShipWeaponData = installed_weapons[mount_index]
	installed_weapons[mount_index] = null

	while not installed_weapons.is_empty() and installed_weapons[installed_weapons.size() - 1] == null:
		installed_weapons.pop_back()

	return removed_weapon

func get_module_slots() -> int:
	if ship_template == null:
		return 0
	if ship_template.body == null:
		return 0
	return ship_template.body.module_slots

func get_used_module_slots() -> int:
	return mini(installed_modules.size(), get_module_slots())

func has_module_capacity() -> bool:
	return installed_modules.size() < get_module_slots()

func can_equip_module(module: ShipModuleData) -> bool:
	if module == null:
		return false
	return has_module_capacity()

func equip_module(module: ShipModuleData) -> bool:
	if not can_equip_module(module):
		return false
	installed_modules.append(module)
	current_shield = minf(current_shield, float(get_total_shield_capacity()))
	return true

func remove_module(module_index: int) -> ShipModuleData:
	if module_index < 0 or module_index >= installed_modules.size():
		return null

	var removed_module: ShipModuleData = installed_modules[module_index]
	installed_modules.remove_at(module_index)
	current_shield = minf(current_shield, float(get_total_shield_capacity()))
	return removed_module

func get_total_hull_points() -> int:
	if ship_template == null or ship_template.body == null:
		return 0
	return ship_template.body.hull_points

func get_total_armor() -> int:
	if ship_template == null or ship_template.body == null:
		return get_total_armor_bonus()
	return ship_template.body.armor + get_total_armor_bonus()

func get_total_armor_bonus() -> int:
	var total_armor_bonus: int = 0
	for module: ShipModuleData in installed_modules:
		if module != null:
			total_armor_bonus += module.armor_bonus
	return total_armor_bonus

func get_shield_regeneration() -> float:
	if get_total_shield_capacity() <= 0:
		return 0.0
	if ship_template == null:
		return 0.0
	return ship_template.shield_regeneration

func get_total_shield_capacity() -> int:
	var total_shield_capacity: int = 0
	for module: ShipModuleData in installed_modules:
		if module != null:
			total_shield_capacity += module.shield_capacity_bonus
	return total_shield_capacity

func get_total_cargo_capacity() -> int:
	if ship_template == null or ship_template.wings == null:
		return get_total_cargo_bonus()

	var total_cargo_capacity: int = ship_template.wings.cargo_capacity + get_total_cargo_bonus()
	return total_cargo_capacity

func get_total_cargo_bonus() -> int:
	var total_cargo_bonus: int = 0
	for module: ShipModuleData in installed_modules:
		if module != null:
			total_cargo_bonus += module.cargo_capacity_bonus
	return total_cargo_bonus

func get_max_speed() -> float:
	if ship_template == null or ship_template.tail == null:
		return get_speed_bonus()

	return ship_template.tail.max_speed + get_speed_bonus()

func get_speed_bonus() -> float:
	var total_speed_bonus: float = 0.0
	for module: ShipModuleData in installed_modules:
		if module != null:
			total_speed_bonus += module.speed_bonus
	return total_speed_bonus

func get_acceleration() -> float:
	if ship_template == null or ship_template.tail == null:
		return get_acceleration_bonus()

	return ship_template.tail.acceleration + get_acceleration_bonus()

func get_acceleration_bonus() -> float:
	var total_acceleration_bonus: float = 0.0
	for module: ShipModuleData in installed_modules:
		if module != null:
			total_acceleration_bonus += module.acceleration_bonus
	return total_acceleration_bonus

func get_boost_multiplier() -> float:
	if ship_template == null or ship_template.tail == null:
		return 0.0
	return ship_template.tail.boost_multiplier
