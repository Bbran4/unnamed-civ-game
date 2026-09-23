class_name Ship
extends CharacterBody3D

## Reusable runtime ship.
##
## ShipData defines the ship's static design.
## Ship stores the runtime state of one actual vessel.
## Controllers provide intent; Ship applies the flight model.
##
## The runtime Ship also owns the current weapon loadout. ShipData only defines
## how many weapon slots the hull supports.

const CRUISE_ACCELERATION_TIME: float = 2.0
const ANGULAR_RESPONSE_TIME: float = 0.75
const THROTTLE_RESPONSE_TIME: float = 1.0
const FLIGHT_ASSIST_MULTIPLIER: float = 4.0
const WEAPON_SCENE: PackedScene = preload("res://scenes/weapons/weapon.tscn")

@export_category("Ship Definition")
@export var ship_data: ShipData

@export_category("Controller")
@export var controller_path: NodePath

@export_category("Installed Equipment")
@export var installed_equipment: Array[EquipmentData] = []

@export_category("Weapon Loadout")
var weapons: Array[Weapon] = []

@export_category("Runtime State")
var current_hull: float = 0.0
var current_shields: float = 0.0
var current_energy: float = 0.0

var throttle: float = 0.0
var boost_active: bool = false
var brake_active: bool = false

var angular_velocity: Vector3 = Vector3.ZERO
var controller: ShipController

var acceleration: float = 0.0
var reverse_acceleration: float = 0.0
var brake_acceleration: float = 0.0
var strafe_acceleration: float = 0.0
var flight_assist_acceleration: float = 0.0
var boost_acceleration: float = 0.0

var max_speed: float = 0.0
var reverse_speed: float = 0.0
var strafe_speed: float = 0.0
var boost_speed: float = 0.0

var pitch_acceleration: float = 0.0
var yaw_acceleration: float = 0.0
var roll_acceleration: float = 0.0

var pitch_speed: float = 0.0
var yaw_speed: float = 0.0
var roll_speed: float = 0.0

var moment_of_inertia: Vector3 = Vector3.ZERO

func _ready() -> void:
	_initialize_from_data()
	_initialize_controller()
	_initialize_weapon_slots()

func _physics_process(delta: float) -> void:
	if controller == null:
		return

	var intent: Dictionary = controller.get_flight_intent(delta)
	_apply_rotation(delta, intent)
	_apply_throttle(delta, intent)
	_apply_translation(delta, intent)
	_apply_weapons(intent)
	move_and_slide()

func _initialize_from_data() -> void:
	if ship_data == null:
		push_warning("Ship has no ShipData assigned: %s" % name)
		return

	current_hull = ship_data.hull_capacity
	current_shields = ship_data.shield_capacity
	current_energy = ship_data.energy_capacity
	_calculate_flight_characteristics()

func _initialize_controller() -> void:
	if controller_path != NodePath():
		controller = get_node_or_null(controller_path) as ShipController

	if controller == null:
		for child in get_children():
			if child is ShipController:
				controller = child
				break

func _initialize_weapon_slots() -> void:
	if ship_data == null:
		return

	weapons.resize(maxi(ship_data.weapon_slots, 0))

func recalculate_flight_characteristics() -> void:
	_calculate_flight_characteristics()

func _calculate_flight_characteristics() -> void:
	var mass: float = get_total_mass_kg()

	if mass <= 0.0:
		return

	acceleration = ship_data.main_engine_thrust_n / mass
	reverse_acceleration = ship_data.reverse_engine_thrust_n / mass
	brake_acceleration = reverse_acceleration
	strafe_acceleration = ship_data.maneuvering_thrust_n / mass
	flight_assist_acceleration = strafe_acceleration * FLIGHT_ASSIST_MULTIPLIER
	boost_acceleration = (ship_data.main_engine_thrust_n + ship_data.boost_thrust_n) / mass

	# Space itself does not impose a maximum speed. These are practical
	# gameplay speed limits derived from how quickly the ship can accelerate.
	max_speed = acceleration * CRUISE_ACCELERATION_TIME
	reverse_speed = reverse_acceleration * CRUISE_ACCELERATION_TIME
	strafe_speed = strafe_acceleration * CRUISE_ACCELERATION_TIME
	boost_speed = boost_acceleration * CRUISE_ACCELERATION_TIME

	moment_of_inertia = _calculate_box_inertia(mass, ship_data.dimensions)

	var pitch_torque: float = ship_data.maneuvering_thrust_n * maxf(ship_data.dimensions.z, 0.01)
	var yaw_torque: float = ship_data.maneuvering_thrust_n * maxf(ship_data.dimensions.z, 0.01)
	var roll_torque: float = ship_data.maneuvering_thrust_n * maxf(ship_data.dimensions.x, 0.01)

	pitch_acceleration = pitch_torque / maxf(moment_of_inertia.x, 0.01)
	yaw_acceleration = yaw_torque / maxf(moment_of_inertia.y, 0.01)
	roll_acceleration = roll_torque / maxf(moment_of_inertia.z, 0.01)

	pitch_speed = pitch_acceleration * ANGULAR_RESPONSE_TIME
	yaw_speed = yaw_acceleration * ANGULAR_RESPONSE_TIME
	roll_speed = roll_acceleration * ANGULAR_RESPONSE_TIME

func _calculate_box_inertia(mass: float, dimensions: Vector3) -> Vector3:
	var width: float = maxf(absf(dimensions.x), 0.01)
	var height: float = maxf(absf(dimensions.y), 0.01)
	var length: float = maxf(absf(dimensions.z), 0.01)

	var inertia_x: float = (mass / 12.0) * (height * height + length * length)
	var inertia_y: float = (mass / 12.0) * (width * width + length * length)
	var inertia_z: float = (mass / 12.0) * (width * width + height * height)

	return Vector3(inertia_x, inertia_y, inertia_z)

func _apply_rotation(delta: float, intent: Dictionary) -> void:
	var target_angular_velocity: Vector3 = Vector3(
		float(intent.get("pitch", 0.0)) * pitch_speed,
		float(intent.get("yaw", 0.0)) * yaw_speed,
		float(intent.get("roll", 0.0)) * roll_speed
	)

	angular_velocity.x = move_toward(
		angular_velocity.x,
		target_angular_velocity.x,
		pitch_acceleration * delta
	)
	angular_velocity.y = move_toward(
		angular_velocity.y,
		target_angular_velocity.y,
		yaw_acceleration * delta
	)
	angular_velocity.z = move_toward(
		angular_velocity.z,
		target_angular_velocity.z,
		roll_acceleration * delta
	)

	rotate_object_local(Vector3.RIGHT, angular_velocity.x * delta)
	rotate_object_local(Vector3.UP, angular_velocity.y * delta)
	rotate_object_local(Vector3.FORWARD, angular_velocity.z * delta)

	global_basis = global_basis.orthonormalized()

func _apply_throttle(delta: float, intent: Dictionary) -> void:
	# Throttle is a persistent requested engine setting. Releasing W/S does
	# not remove throttle, so the ship can maintain its current cruise speed.
	var throttle_input: float = clampf(float(intent.get("throttle", 0.0)), -1.0, 1.0)
	throttle = clampf(
		throttle + throttle_input * delta / THROTTLE_RESPONSE_TIME,
		-1.0,
		1.0
	)

	boost_active = bool(intent.get("boost", false)) and throttle > 0.0
	brake_active = bool(intent.get("brake", false))

func _apply_translation(delta: float, intent: Dictionary) -> void:
	if brake_active:
		# Brake cancels current momentum using derived reverse thrust.
		# It deliberately does not reset throttle, so releasing the brake
		# allows the ship to accelerate back toward its requested speed.
		velocity = velocity.move_toward(Vector3.ZERO, brake_acceleration * delta)
		return

	var forward: Vector3 = -global_transform.basis.z
	var forward_speed: float = velocity.dot(forward)

	var target_forward_speed: float = throttle * max_speed

	if throttle < 0.0:
		target_forward_speed = throttle * reverse_speed
	elif boost_active:
		target_forward_speed = boost_speed

	var speed_difference: float = target_forward_speed - forward_speed

	if abs(speed_difference) > 0.001:
		var response: float = acceleration if speed_difference > 0.0 else reverse_acceleration
		var forward_delta: float = clampf(speed_difference, -response * delta, response * delta)
		velocity += forward * forward_delta

	var strafe: float = clampf(float(intent.get("strafe", 0.0)), -1.0, 1.0)

	if abs(strafe) > 0.001:
		var right: Vector3 = global_transform.basis.x
		var lateral_velocity: Vector3 = velocity - forward * forward_speed
		var lateral_speed: float = lateral_velocity.dot(right)
		var target_lateral_speed: float = strafe * strafe_speed
		var lateral_difference: float = target_lateral_speed - lateral_speed
		var lateral_delta: float = clampf(
			lateral_difference,
			-strafe_acceleration * delta,
			strafe_acceleration * delta
		)
		velocity += right * lateral_delta
	else:
		# Flight assist uses available maneuvering thrust to bleed off lateral
		# momentum. Re-read forward speed here because main engine thrust may have
		# changed velocity earlier in this frame.
		var current_forward_speed: float = velocity.dot(forward)
		var lateral_velocity: Vector3 = velocity - forward * current_forward_speed
		var corrected_lateral_velocity: Vector3 = lateral_velocity.move_toward(
			Vector3.ZERO,
			flight_assist_acceleration * delta
		)
		velocity = forward * current_forward_speed + corrected_lateral_velocity

func _apply_weapons(intent: Dictionary) -> void:
	if not bool(intent.get("fire", false)):
		return

	for weapon: Weapon in weapons:
		if weapon != null:
			weapon.try_fire()

func equip_weapon(weapon_data: WeaponData, slot_index: int = -1) -> Weapon:
	if weapon_data == null or ship_data == null:
		return null

	if ship_data.weapon_slots <= 0:
		push_warning("%s has no weapon slots." % name)
		return null

	if slot_index < 0:
		slot_index = _find_free_weapon_slot()

	if slot_index < 0 or slot_index >= ship_data.weapon_slots:
		push_warning("Invalid weapon slot %d on %s." % [slot_index, name])
		return null

	if weapons[slot_index] != null:
		push_warning("Weapon slot %d on %s is already occupied." % [slot_index, name])
		return null

	var mount_path: NodePath = NodePath("WeaponMounts/WeaponMount_%d" % slot_index)
	var mount: Node3D = get_node_or_null(mount_path) as Node3D

	if mount == null:
		push_warning("Missing weapon mount for slot %d on %s." % [slot_index, name])
		return null

	var weapon: Weapon = WEAPON_SCENE.instantiate() as Weapon

	if weapon == null:
		push_error("Weapon scene must instantiate Weapon.")
		return null

	weapon.weapon_data = weapon_data
	weapon.set_ship(self)
	mount.add_child(weapon)
	weapons[slot_index] = weapon

	installed_equipment.append(weapon_data)
	recalculate_flight_characteristics()

	return weapon

func unequip_weapon(slot_index: int) -> Weapon:
	if slot_index < 0 or slot_index >= weapons.size():
		return null

	var weapon: Weapon = weapons[slot_index]

	if weapon == null:
		return null

	weapons[slot_index] = null

	if weapon.weapon_data != null:
		installed_equipment.erase(weapon.weapon_data)

	recalculate_flight_characteristics()
	weapon.queue_free()

	return weapon

func get_weapon(slot_index: int) -> Weapon:
	if slot_index < 0 or slot_index >= weapons.size():
		return null

	return weapons[slot_index]

func get_weapon_count() -> int:
	var count: int = 0

	for weapon: Weapon in weapons:
		if weapon != null:
			count += 1

	return count

func _find_free_weapon_slot() -> int:
	for index: int in range(weapons.size()):
		if weapons[index] == null:
			return index

	return -1

func get_total_mass_kg() -> float:
	var total_mass: float = 0.0

	if ship_data != null:
		total_mass += ship_data.hull_mass_kg

	for equipment: EquipmentData in installed_equipment:
		if equipment != null:
			total_mass += maxf(equipment.mass_kg, 0.0)

	# Cargo mass will contribute here later.
	return total_mass

func add_equipment(equipment: EquipmentData) -> void:
	if equipment == null:
		return

	installed_equipment.append(equipment)
	recalculate_flight_characteristics()

func remove_equipment(equipment: EquipmentData) -> void:
	if equipment == null:
		return

	if installed_equipment.has(equipment):
		installed_equipment.erase(equipment)
		recalculate_flight_characteristics()

func get_equipment_mass_kg() -> float:
	var equipment_mass: float = 0.0

	for equipment: EquipmentData in installed_equipment:
		if equipment != null:
			equipment_mass += maxf(equipment.mass_kg, 0.0)

	return equipment_mass

func get_moment_of_inertia_kg_m2() -> Vector3:
	return moment_of_inertia

signal damage_received(amount: float, source: Node, remaining_hull: float)
signal shields_hit(amount: float, source: Node, remaining_shields: float)
signal hull_hit(amount: float, source: Node, remaining_hull: float)

## Entry point used by DamageSystem.
##
## Incoming damage is processed by shields first. Any damage that remains
## after shields are depleted is applied to the hull.
func receive_damage(amount: float, source: Node = null) -> void:
	if is_destroyed():
		return

	var damage: float = maxf(amount, 0.0)

	if damage <= 0.0:
		return

	var shield_result: Dictionary = ShieldSystem.absorb_damage(
		current_shields,
		damage
	)

	current_shields = float(shield_result["remaining_shields"])
	var shield_damage: float = float(shield_result["shield_damage"])
	var overflow_damage: float = float(shield_result["overflow_damage"])

	if shield_damage > 0.0:
		shields_hit.emit(shield_damage, source, current_shields)

	if overflow_damage > 0.0:
		var hull_capacity: float = 0.0

		if ship_data != null:
			hull_capacity = ship_data.hull_capacity

		var hull_result: Dictionary = HullSystem.apply_damage(
			current_hull,
			overflow_damage,
			hull_capacity
		)

		current_hull = float(hull_result["remaining_hull"])
		var hull_damage: float = float(hull_result["hull_damage"])

		if hull_damage > 0.0:
			hull_hit.emit(hull_damage, source, current_hull)

	damage_received.emit(damage, source, current_hull)


func get_hull_fraction() -> float:
	if ship_data == null or ship_data.hull_capacity <= 0.0:
		return 0.0
	return current_hull / ship_data.hull_capacity

func get_shield_fraction() -> float:
	if ship_data == null or ship_data.shield_capacity <= 0.0:
		return 0.0
	return current_shields / ship_data.shield_capacity

func get_energy_fraction() -> float:
	if ship_data == null or ship_data.energy_capacity <= 0.0:
		return 0.0
	return current_energy / ship_data.energy_capacity

func is_destroyed() -> bool:
	return current_hull <= 0.0

func reset_runtime_state() -> void:
	if ship_data == null:
		return

	current_hull = ship_data.hull_capacity
	current_shields = ship_data.shield_capacity
	current_energy = ship_data.energy_capacity
	throttle = 0.0
	boost_active = false
	brake_active = false
	velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func get_speed() -> float:
	return velocity.length()

func get_throttle_percent() -> float:
	return throttle
