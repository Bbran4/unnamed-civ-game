extends CharacterBody2D

@export var ship_data: ShipData
@export var move_speed: float = 130.0
@export var acceleration: float = 500.0
@export var max_hull: float = 50.0
@export var max_shield: float = 50.0
@export var armor: float = 0.0
@export var armor_constant: float = 100.0
@export var shield_regen_rate: float = 15.0
@export var shield_regen_delay: float = 2.0
@export var preferred_distance: float = 300.0
@export var fire_cooldown: float = 0.8
@export var projectile_scene: PackedScene
@export var salvage_scene: PackedScene
@export var salvage_reward: int = 50

var current_hull: float = 50.0
var current_shield: float = 50.0
var shield_regen_remaining: float = 0.0
var fire_cooldown_remaining: float = 0.0
var player_ship: Node2D
var is_destroying: bool = false
var weapon_ammo: Dictionary = {}

@onready var weapon_muzzles: Array[Marker2D] = [$WeaponMuzzles/Muzzle1, $WeaponMuzzles/Muzzle2, $WeaponMuzzles/Muzzle3, $WeaponMuzzles/Muzzle4]
@onready var hull_visual: Polygon2D = $Hull
@onready var status_bars: Control = $EnemyStatusBars

func _ready() -> void:
	_apply_ship_data()
	current_hull = max_hull
	current_shield = max_shield
	_update_status_bars()
	_update_status_bar_transform()
	_initialize_weapon_ammo()
	player_ship = get_tree().get_first_node_in_group("player_ship") as Node2D

func _physics_process(delta: float) -> void:
	_shield_regeneration(delta)
	_update_status_bar_transform()
	if not is_instance_valid(player_ship):
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		_update_status_bar_transform()
		return

	var offset_to_player: Vector2 = player_ship.global_position - global_position
	var distance_to_player: float = offset_to_player.length()
	var direction_to_player: Vector2 = offset_to_player.normalized()

	if distance_to_player > preferred_distance + 50.0:
		velocity = velocity.move_toward(direction_to_player * move_speed, acceleration * delta)
	elif distance_to_player < preferred_distance - 50.0:
		velocity = velocity.move_toward(-direction_to_player * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

	rotation = offset_to_player.angle()
	move_and_slide()
	_update_status_bar_transform()

	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
	if distance_to_player < 550.0:
		_fire_at_player()

func _initialize_weapon_ammo() -> void:
	weapon_ammo.clear()
	if ship_data == null:
		return

	for weapon_index: int in range(ship_data.weapons.size()):
		var weapon: ShipWeaponData = ship_data.get_weapon(weapon_index)
		if weapon != null and weapon.ammo_capacity > 0:
			weapon_ammo[weapon_index] = weapon.ammo_capacity

func _apply_ship_data() -> void:
	if ship_data == null:
		return

	max_hull = float(ship_data.get_total_hull_points())
	max_shield = float(ship_data.get_total_shield_capacity())
	armor = float(ship_data.get_total_armor())
	move_speed = ship_data.get_max_speed() * 0.5
	acceleration = ship_data.get_acceleration()
	shield_regen_rate = ship_data.shield_regeneration if max_shield > 0.0 else 0.0

func _update_status_bar_transform() -> void:
	status_bars.global_position = global_position + Vector2(0.0, -55.0)
	status_bars.rotation = -global_rotation

func _fire_at_player() -> void:
	if fire_cooldown_remaining > 0.0:
		return
	if projectile_scene == null:
		return

	var weapon_mount_count: int = ship_data.get_weapon_mounts() if ship_data != null else 1
	var active_mount_count: int = mini(weapon_mount_count, weapon_muzzles.size())
	var lowest_fire_interval: float = INF

	for mount_index: int in range(active_mount_count):
		var weapon: ShipWeaponData = ship_data.get_weapon(mount_index) if ship_data != null else null
		if weapon == null:
			continue

		var projectile_instance: Node = projectile_scene.instantiate()
		if projectile_instance is Node2D:
			var projectile_2d: Node2D = projectile_instance
			var weapon_muzzle: Marker2D = weapon_muzzles[mount_index]
			projectile_2d.global_position = weapon_muzzle.global_position
			projectile_2d.global_rotation = global_rotation
			projectile_2d.set("owner_group", "enemy_projectile")
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
				projectile_2d.set("target", player_ship)
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

	if remaining_damage > 0.0:
		var hull_damage: float = _calculate_hull_damage(remaining_damage * hull_multiplier)
		current_hull = maxf(0.0, current_hull - hull_damage)

	_update_status_bars()
	_flash_hit()

	if current_hull <= 0.0 and not is_destroying:
		is_destroying = true
		call_deferred("_destroy")

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
	_update_status_bars()

func _update_status_bars() -> void:
	status_bars.set_values(current_hull, max_hull, current_shield, max_shield)

func _flash_hit() -> void:
	hull_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(hull_visual, "modulate", Color(0.72, 0.12, 0.1, 1.0), 0.08)

func _destroy() -> void:
	if salvage_scene != null:
		var salvage_instance: Node = salvage_scene.instantiate()
		if salvage_instance is Node2D:
			var salvage_2d: Node2D = salvage_instance
			salvage_2d.global_position = global_position
			salvage_2d.set("credit_value", salvage_reward)
			get_tree().current_scene.add_child(salvage_2d)

	queue_free()
