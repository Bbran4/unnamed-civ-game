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

const THROTTLE_RESPONSE_TIME: float = 1.0
const WEAPON_SCENE: PackedScene = preload("res://scenes/weapons/weapon.tscn")


enum FlightEnvironment {
	SPACE,
	ATMOSPHERE,
	SURFACE
}

@export_category("Ship Definition")
@export var ship_data: ShipData

@export_category("Controller")
@export var controller_path: NodePath

@export_category("Installed Equipment")
@export var installed_equipment: Array[EquipmentData] = []

@export_category("Weapon Loadout")
var weapons: Array[Weapon] = []

@export_category("Destruction State")
var destroyed_state: bool = false

@export_category("Runtime State")
var current_hull: float = 0.0
var current_shields: float = 0.0
var current_energy: float = 0.0
var shield_recharge_delay_remaining: float = 0.0
var energy_recharge_delay_remaining: float = 0.0

var throttle: float = 0.0
var flight_environment: FlightEnvironment = FlightEnvironment.SPACE
var current_planet: Planet = null
var atmosphere_fraction: float = 0.0
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

func _ready() -> void:
	destroyed_state = false
	_initialize_from_data()
	_initialize_controller()
	_initialize_weapon_slots()

func _physics_process(delta: float) -> void:
	_update_resource_regeneration(delta)

	if controller == null:
		return

	var intent: Dictionary = controller.get_flight_intent(delta)
	_apply_rotation(delta, intent)
	_apply_throttle(delta, intent)
	_apply_translation(delta, intent)
	_apply_atmospheric_drag(delta)
	_apply_weapons(intent)
	move_and_slide()

func _initialize_from_data() -> void:
	if ship_data == null:
		push_warning("Ship has no ShipData assigned: %s" % name)
		return

	current_hull = ship_data.hull_capacity
	current_shields = ship_data.shield_capacity
	current_energy = ship_data.energy_capacity
	shield_recharge_delay_remaining = 0.0
	energy_recharge_delay_remaining = 0.0
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
	if ship_data == null:
		return

	acceleration = maxf(ship_data.acceleration_mps2, 0.0)
	reverse_acceleration = maxf(ship_data.reverse_acceleration_mps2, 0.0)
	brake_acceleration = reverse_acceleration
	strafe_acceleration = maxf(ship_data.strafe_acceleration_mps2, 0.0)
	flight_assist_acceleration = maxf(ship_data.flight_assist_acceleration_mps2, 0.0)
	boost_acceleration = maxf(ship_data.boost_acceleration_mps2, 0.0)

	max_speed = maxf(ship_data.max_speed_mps, 0.0)
	reverse_speed = maxf(ship_data.reverse_speed_mps, 0.0)
	strafe_speed = maxf(ship_data.strafe_speed_mps, 0.0)
	boost_speed = maxf(ship_data.boost_speed_mps, max_speed)

	pitch_speed = deg_to_rad(maxf(ship_data.pitch_turn_rate_deg_s, 0.0))
	yaw_speed = deg_to_rad(maxf(ship_data.yaw_turn_rate_deg_s, 0.0))
	roll_speed = deg_to_rad(maxf(ship_data.roll_turn_rate_deg_s, 0.0))

	pitch_acceleration = deg_to_rad(maxf(ship_data.pitch_turn_acceleration_deg_s2, 0.0))
	yaw_acceleration = deg_to_rad(maxf(ship_data.yaw_turn_acceleration_deg_s2, 0.0))
	roll_acceleration = deg_to_rad(maxf(ship_data.roll_turn_acceleration_deg_s2, 0.0))

func _apply_rotation(delta: float, intent: Dictionary) -> void:
	var target_angular_velocity: Vector3 = Vector3(
		clampf(float(intent.get("pitch", 0.0)), -1.0, 1.0) * pitch_speed,
		clampf(float(intent.get("yaw", 0.0)), -1.0, 1.0) * yaw_speed,
		clampf(float(intent.get("roll", 0.0)), -1.0, 1.0) * roll_speed
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

	var boost_requested: bool = bool(intent.get("boost", false)) and throttle > 0.0
	boost_active = false

	if boost_requested:
		var boost_drain: float = maxf(ship_data.boost_energy_drain_per_second, 0.0) * delta
		var drained_energy: float = drain_energy(boost_drain)
		boost_active = drained_energy > 0.0

	brake_active = bool(intent.get("brake", false))

func _apply_translation(delta: float, intent: Dictionary) -> void:
	if brake_active:
		# Brake cancels current momentum using the ship's direct brake acceleration.
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

func set_flight_environment(
	environment: FlightEnvironment,
	planet: Planet = null,
	new_atmosphere_fraction: float = 0.0
) -> void:
	flight_environment = environment
	current_planet = planet
	atmosphere_fraction = clampf(new_atmosphere_fraction, 0.0, 1.0)


func _apply_atmospheric_drag(delta: float) -> void:
	if flight_environment != FlightEnvironment.ATMOSPHERE:
		return

	if current_planet == null or current_planet.planet_data == null:
		return

	var drag_strength: float = maxf(
		current_planet.planet_data.atmospheric_drag_strength,
		0.0
	)
	var drag_factor: float = drag_strength * atmosphere_fraction

	if drag_factor <= 0.0 or velocity.length_squared() <= 0.0001:
		return

	var drag_acceleration: float = velocity.length() * drag_factor
	velocity = velocity.move_toward(Vector3.ZERO, drag_acceleration * delta)


func _update_resource_regeneration(delta: float) -> void:
	if ship_data == null or destroyed_state:
		return

	shield_recharge_delay_remaining = maxf(
		shield_recharge_delay_remaining - delta,
		0.0
	)
	energy_recharge_delay_remaining = maxf(
		energy_recharge_delay_remaining - delta,
		0.0
	)

	if shield_recharge_delay_remaining <= 0.0:
		current_shields = move_toward(
			current_shields,
			maxf(ship_data.shield_capacity, 0.0),
			maxf(ship_data.shield_recharge_rate, 0.0) * delta
		)

	if energy_recharge_delay_remaining <= 0.0:
		current_energy = move_toward(
			current_energy,
			maxf(ship_data.energy_capacity, 0.0),
			maxf(ship_data.energy_recharge_rate, 0.0) * delta
		)

func _apply_weapons(intent: Dictionary) -> void:
	if not bool(intent.get("fire", false)):
		return

	var fire_direction: Vector3 = intent.get("fire_direction", Vector3.ZERO)

	for weapon: Weapon in weapons:
		if weapon != null:
			weapon.try_fire(fire_direction)

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

signal damage_received(amount: float, source: Node, remaining_hull: float)
signal shields_hit(amount: float, source: Node, remaining_shields: float)
signal hull_hit(amount: float, source: Node, remaining_hull: float)
signal destroyed(source: Node)

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

	if ship_data != null:
		shield_recharge_delay_remaining = maxf(ship_data.shield_recharge_delay, 0.0)

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

	if overflow_damage > 0.0 and current_hull <= 0.0:
		DestructionSystem.destroy(self, source)


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
	return destroyed_state

func reset_runtime_state() -> void:
	if ship_data == null:
		return

	current_hull = ship_data.hull_capacity
	current_shields = ship_data.shield_capacity
	current_energy = ship_data.energy_capacity
	shield_recharge_delay_remaining = 0.0
	energy_recharge_delay_remaining = 0.0
	destroyed_state = false
	throttle = 0.0
	boost_active = false
	brake_active = false
	velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func consume_energy(amount: float) -> bool:
	if ship_data == null:
		return false

	var cost: float = maxf(amount, 0.0)

	if current_energy < cost:
		return false

	current_energy -= cost
	energy_recharge_delay_remaining = maxf(ship_data.energy_recharge_delay, 0.0)
	return true


## Drain up to the requested amount of ship energy.
##
## Unlike consume_energy(), this method allows a continuous system such as
## boost to partially drain the remaining energy before reaching zero.
func drain_energy(amount: float) -> float:
	if ship_data == null:
		return 0.0

	var drain: float = minf(maxf(amount, 0.0), current_energy)

	if drain <= 0.0:
		return 0.0

	current_energy -= drain
	energy_recharge_delay_remaining = maxf(ship_data.energy_recharge_delay, 0.0)
	return drain


func get_shield_recharge_delay_remaining() -> float:
	return shield_recharge_delay_remaining


func get_energy_recharge_delay_remaining() -> float:
	return energy_recharge_delay_remaining


func get_speed() -> float:
	return velocity.length()

func get_throttle_percent() -> float:
	return throttle
