extends CharacterBody2D

enum ControlStyle {
	ROTATION_KEYS,
	MOUSE_AIM
}

@export var ship_data: ShipData

var owned_ship_data: OwnedShipData
@export var forward_acceleration: float = 600.0
@export var reverse_acceleration: float = 350.0
@export var turn_speed: float = 3.5
@export var momentum_decay_time: float = 1.0
@export var max_speed: float = 550.0
@export var boost_max_speed: float = 800.0
@export var boost_acceleration: float = 850.0
@export var max_hull: float = 100.0
@export var max_shield: float = 50.0
@export var armor: float = 0.0
@export var armor_constant: float = 100.0
@export var shield_regen_rate: float = 15.0
@export var shield_regen_delay: float = 2.0
@export var primary_fire_cooldown: float = 0.18
@export var warp_enemy_detection_range: float = 1400.0
@export var projectile_scene: PackedScene

var current_hull: float = 100.0
var current_shield: float = 50.0
var shield_regen_remaining: float = 0.0
var fire_cooldown_remaining: float = 0.0
var control_style: ControlStyle = ControlStyle.ROTATION_KEYS
var weapon_ammo: Dictionary = {}

@onready var weapon_muzzles: Array[Marker2D] = [$WeaponMuzzles/Muzzle1, $WeaponMuzzles/Muzzle2, $WeaponMuzzles/Muzzle3, $WeaponMuzzles/Muzzle4]
@onready var camera: Camera2D = $Camera2D
@onready var status_bars: Control = $PlayerStatusBars/Bars

func _ready() -> void:
	if ship_data == null:
		push_error("Player ship template is not configured.")
		return

	if WorldState.current_owned_ship == null or WorldState.current_owned_ship.ship_template == null or WorldState.current_owned_ship.ship_template.id != ship_data.id:
		WorldState.current_owned_ship = OwnedShipData.create_from_template(ship_data)
	owned_ship_data = WorldState.current_owned_ship
	_apply_ship_data()
	current_hull = owned_ship_data.current_hull
	current_shield = owned_ship_data.current_shield
	control_style = WorldState.control_style as ControlStyle

	if WorldState.returning_from_station:
		global_position = WorldState.station_exit_position
		WorldState.returning_from_station = false
	else:
		global_position = WorldState.system_entry_position

	_initialize_weapon_ammo()
	_update_status_bars()

func _physics_process(delta: float) -> void:
	_shield_regeneration(delta)

	if WorldState.map_open:
		var reference_velocity: Vector2 = get_space_reference_velocity()
		velocity = reference_velocity
		move_and_slide()
		camera.update_speed_zoom(false, delta)
		return

	var reference_velocity: Vector2 = get_space_reference_velocity()
	var relative_velocity: Vector2 = velocity - reference_velocity
	var forward_direction: Vector2 = Vector2.RIGHT.rotated(rotation)
	var boost_active: bool = Input.is_action_pressed("boost")
	var current_max_speed: float = max_speed

	if control_style == ControlStyle.ROTATION_KEYS:
		boost_active = boost_active and Input.is_action_pressed("move_up")
		var turn_input: float = Input.get_axis("move_left", "move_right")
		if turn_input != 0.0:
			rotation += turn_input * turn_speed * delta
	else:
		var mouse_position: Vector2 = get_global_mouse_position()
		var direction_to_mouse: Vector2 = mouse_position - global_position
		if direction_to_mouse.length_squared() > 0.0:
			rotation = direction_to_mouse.angle()

		var strafe_input: float = Input.get_axis("move_left", "move_right")
		if strafe_input != 0.0:
			var right_direction: Vector2 = Vector2.DOWN.rotated(rotation)
			relative_velocity += right_direction * strafe_input * forward_acceleration * delta

	forward_direction = Vector2.RIGHT.rotated(rotation)

	if boost_active:
		current_max_speed = boost_max_speed
		relative_velocity += forward_direction * boost_acceleration * delta

	if Input.is_action_pressed("move_up"):
		relative_velocity += forward_direction * forward_acceleration * delta

	if Input.is_action_pressed("move_down"):
		relative_velocity -= forward_direction * reverse_acceleration * delta
	elif not Input.is_action_pressed("move_up"):
		var momentum_decay_acceleration: float = max_speed / momentum_decay_time
		relative_velocity = relative_velocity.move_toward(Vector2.ZERO, momentum_decay_acceleration * delta)

	if relative_velocity.length() > current_max_speed:
		relative_velocity = relative_velocity.normalized() * current_max_speed

	velocity = reference_velocity + relative_velocity
	move_and_slide()
	camera.update_speed_zoom(boost_active, delta)

	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
	if Input.is_action_pressed("primary_fire"):
		_fire_primary()

func _initialize_weapon_ammo() -> void:
	weapon_ammo.clear()
	if owned_ship_data == null:
		return

	for weapon_index: int in range(owned_ship_data.installed_weapons.size()):
		var weapon: ShipWeaponData = owned_ship_data.get_weapon(weapon_index)
		if weapon != null and weapon.ammo_capacity > 0:
			weapon_ammo[weapon_index] = weapon.ammo_capacity

func _apply_ship_data() -> void:
	if owned_ship_data == null:
		return

	max_hull = float(owned_ship_data.get_total_hull_points())
	max_shield = float(owned_ship_data.get_total_shield_capacity())
	armor = float(owned_ship_data.get_total_armor())
	max_speed = owned_ship_data.get_max_speed()
	forward_acceleration = owned_ship_data.get_acceleration()
	boost_max_speed = max_speed * owned_ship_data.get_boost_multiplier()
	shield_regen_rate = owned_ship_data.get_shield_regeneration()

func get_space_reference_velocity() -> Vector2:
	var space_system: Node = get_tree().get_first_node_in_group("space_system")
	if space_system == null:
		return Vector2.ZERO

	if not space_system.has_method("get_reference_velocity_at_position"):
		return Vector2.ZERO

	var velocity_result: Variant = space_system.call(
		"get_reference_velocity_at_position",
		global_position
	)
	if velocity_result is Vector2:
		return velocity_result as Vector2

	return Vector2.ZERO

func is_in_danger_zone() -> bool:
	if shield_regen_remaining > 0.0:
		return true

	for enemy_node: Node in get_tree().get_nodes_in_group("enemy_ship"):
		var enemy_ship: Node2D = enemy_node as Node2D
		if enemy_ship == null:
			continue

		var distance_to_enemy: float = global_position.distance_to(enemy_ship.global_position)
		if distance_to_enemy <= warp_enemy_detection_range:
			return true

	return false

func set_control_style(new_control_style: ControlStyle) -> void:
	control_style = new_control_style
	WorldState.control_style = new_control_style as int

func _fire_primary() -> void:
	if fire_cooldown_remaining > 0.0 or projectile_scene == null:
		return

	var weapon_mount_count: int = owned_ship_data.get_weapon_mounts() if owned_ship_data != null else 1
	var active_mount_count: int = mini(weapon_mount_count, weapon_muzzles.size())
	var lowest_fire_interval: float = INF

	for mount_index: int in range(active_mount_count):
		var weapon: ShipWeaponData = owned_ship_data.get_weapon(mount_index) if owned_ship_data != null else null
		if weapon == null:
			continue

		var projectile_instance: Node = projectile_scene.instantiate()
		if projectile_instance is Node2D:
			var projectile_2d: Node2D = projectile_instance
			var weapon_muzzle: Marker2D = weapon_muzzles[mount_index]
			projectile_2d.global_position = weapon_muzzle.global_position
			projectile_2d.global_rotation = global_rotation
			projectile_2d.set("owner_group", "player_projectile")
			if weapon.ammo_capacity > 0:
				var remaining_ammo: int = weapon_ammo.get(mount_index, weapon.ammo_capacity)
				if remaining_ammo <= 0:
					continue
				weapon_ammo[mount_index] = remaining_ammo - 1

			projectile_2d.set("damage", weapon.damage)
			projectile_2d.set("speed", weapon.projectile_speed)
			projectile_2d.set("lifetime", weapon.range / maxf(weapon.projectile_speed, 1.0))
			projectile_2d.set("projectile_type", weapon.weapon_type)
			projectile_2d.set("shield_damage_multiplier", weapon.shield_damage_multiplier)
			projectile_2d.set("hull_damage_multiplier", weapon.hull_damage_multiplier)
			projectile_2d.set("tracking", weapon.tracking)
			projectile_2d.set("tracking_turn_speed", weapon.tracking_turn_speed)
			if weapon.tracking:
				var missile_target: Node2D = get_tree().get_first_node_in_group("enemy_ship") as Node2D
				projectile_2d.set("target", missile_target)
			get_tree().current_scene.add_child(projectile_2d)
			var fire_interval: float = 1.0 / maxf(weapon.fire_rate, 0.01)
			lowest_fire_interval = minf(lowest_fire_interval, fire_interval)

	if lowest_fire_interval < INF:
		fire_cooldown_remaining = lowest_fire_interval

func take_damage(damage_amount: float, damage_type: String = "energy", shield_multiplier: float = 1.0, hull_multiplier: float = 1.0) -> void:
	shield_regen_remaining = shield_regen_delay
	var remaining_damage: float = damage_amount

	if current_shield > 0.0:
		var shield_damage: float = minf(current_shield, remaining_damage * shield_multiplier)
		current_shield -= shield_damage
		remaining_damage -= shield_damage
		if owned_ship_data != null:
			owned_ship_data.current_shield = current_shield

	if remaining_damage > 0.0:
		var hull_damage: float = _calculate_hull_damage(remaining_damage * hull_multiplier)
		current_hull = maxf(0.0, current_hull - hull_damage)
		if owned_ship_data != null:
			owned_ship_data.current_hull = current_hull

	_update_status_bars()
	camera.shake(0.06, 2.0)

	if current_hull <= 0.0:
		queue_free()

func _calculate_hull_damage(incoming_hull_damage: float) -> float:
	if armor <= 0.0:
		return incoming_hull_damage

	var armor_constant_value: float = maxf(0.001, armor_constant)
	var damage_multiplier: float = armor_constant_value / (armor_constant_value + armor)
	return incoming_hull_damage * damage_multiplier

func _shield_regeneration(delta: float) -> void:
	if shield_regen_remaining > 0.0:
		shield_regen_remaining = maxf(0.0, shield_regen_remaining - delta)
		return

	if current_shield >= max_shield:
		return

	current_shield = minf(max_shield, current_shield + shield_regen_rate * delta)
	if owned_ship_data != null:
		owned_ship_data.current_shield = current_shield
	_update_status_bars()

func _update_status_bars() -> void:
	status_bars.set_values(current_hull, max_hull, current_shield, max_shield)
