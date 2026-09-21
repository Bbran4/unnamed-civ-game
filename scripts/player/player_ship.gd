extends CharacterBody2D

@export var forward_acceleration: float = 600.0
@export var reverse_acceleration: float = 350.0
@export var turn_speed: float = 3.5
@export var momentum_decay_time: float = 1.0
@export var max_speed: float = 550.0
@export var boost_max_speed: float = 800.0
@export var boost_acceleration: float = 850.0
@export var max_hull: float = 100.0
@export var max_shield: float = 50.0
@export var shield_regen_rate: float = 15.0
@export var shield_regen_delay: float = 2.0
@export var primary_fire_cooldown: float = 0.18
@export var projectile_scene: PackedScene

var current_hull: float = 100.0
var current_shield: float = 50.0
var shield_regen_remaining: float = 0.0
var fire_cooldown_remaining: float = 0.0

@onready var weapon_muzzle: Marker2D = $WeaponMuzzle
@onready var camera: Camera2D = $Camera2D
@onready var status_bars: Control = $PlayerStatusBars/Bars

func _ready() -> void:
	current_hull = max_hull
	current_shield = max_shield
	_update_status_bars()

func _physics_process(delta: float) -> void:
	_shield_regeneration(delta)

	var turn_input: float = Input.get_axis("move_left", "move_right")

	if turn_input != 0.0:
		rotation += turn_input * turn_speed * delta

	var forward_direction: Vector2 = Vector2.RIGHT.rotated(rotation)
	var boost_active: bool = Input.is_action_pressed("boost") and Input.is_action_pressed("move_up")
	var current_max_speed: float = max_speed

	if boost_active:
		current_max_speed = boost_max_speed
		velocity += forward_direction * boost_acceleration * delta

	if Input.is_action_pressed("move_up"):
		velocity += forward_direction * forward_acceleration * delta

	if Input.is_action_pressed("move_down"):
		velocity -= forward_direction * reverse_acceleration * delta
	elif not Input.is_action_pressed("move_up"):
		var momentum_decay_acceleration: float = max_speed / momentum_decay_time
		velocity = velocity.move_toward(
			Vector2.ZERO,
			momentum_decay_acceleration * delta
		)

	if velocity.length() > current_max_speed:
		velocity = velocity.normalized() * current_max_speed

	move_and_slide()

	camera.update_speed_zoom(boost_active, delta)

	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
	if Input.is_action_pressed("primary_fire"):
		_fire_primary()

func _fire_primary() -> void:
	if fire_cooldown_remaining > 0.0:
		return
	if projectile_scene == null:
		return

	var projectile_instance: Node = projectile_scene.instantiate()
	if projectile_instance is Node2D:
		var projectile_2d: Node2D = projectile_instance
		projectile_2d.global_position = weapon_muzzle.global_position
		projectile_2d.global_rotation = global_rotation
		projectile_2d.set("owner_group", "player_projectile")
		get_tree().current_scene.add_child(projectile_2d)
		fire_cooldown_remaining = primary_fire_cooldown

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
	camera.shake(0.06, 2.0)

	if current_hull <= 0.0:
		queue_free()

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
