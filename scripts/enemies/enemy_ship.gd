extends CharacterBody2D

@export var move_speed: float = 130.0
@export var acceleration: float = 500.0
@export var max_hull: float = 50.0
@export var max_shield: float = 50.0
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

@onready var weapon_muzzle: Marker2D = $WeaponMuzzle
@onready var visual: Polygon2D = $Visual
@onready var status_bars: Control = $EnemyStatusBars

func _ready() -> void:
	current_hull = max_hull
	current_shield = max_shield
	_update_status_bars()
	player_ship = get_tree().get_first_node_in_group("player_ship") as Node2D

func _physics_process(delta: float) -> void:
	_shield_regeneration(delta)
	if not is_instance_valid(player_ship):
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
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

	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
	if distance_to_player < 550.0:
		_fire_at_player()

func _fire_at_player() -> void:
	if fire_cooldown_remaining > 0.0:
		return
	if projectile_scene == null:
		return

	var projectile_instance: Node = projectile_scene.instantiate()
	if projectile_instance is Node2D:
		var projectile_2d: Node2D = projectile_instance
		projectile_2d.global_position = weapon_muzzle.global_position
		projectile_2d.global_rotation = global_rotation
		projectile_2d.set("owner_group", "enemy_projectile")
		get_tree().current_scene.add_child(projectile_2d)
		fire_cooldown_remaining = fire_cooldown

func take_damage(damage_amount: float) -> void:
	shield_regen_remaining = shield_regen_delay
	var remaining_damage: float = damage_amount

	if current_shield > 0.0:
		var shield_damage: float = minf(current_shield, remaining_damage)
		current_shield -= shield_damage
		remaining_damage -= shield_damage

	if remaining_damage > 0.0:
		current_hull = maxf(0.0, current_hull - remaining_damage)

	_update_status_bars()
	_flash_hit()

	if current_hull <= 0.0 and not is_destroying:
		is_destroying = true
		call_deferred("_destroy")

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
	visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 0.3, 0.25, 1.0), 0.08)

func _destroy() -> void:
	if salvage_scene != null:
		var salvage_instance: Node = salvage_scene.instantiate()
		if salvage_instance is Node2D:
			var salvage_2d: Node2D = salvage_instance
			salvage_2d.global_position = global_position
			salvage_2d.set("credit_value", salvage_reward)
			get_tree().current_scene.add_child(salvage_2d)

	queue_free()
