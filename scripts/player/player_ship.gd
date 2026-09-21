extends CharacterBody2D

@export var forward_acceleration: float = 650.0
@export var reverse_acceleration: float = 350.0
@export var turn_speed: float = 3.5
@export var braking_acceleration: float = 850.0
@export var max_speed: float = 700.0
@export var max_hull: float = 100.0
@export var primary_fire_cooldown: float = 0.18
@export var projectile_scene: PackedScene

var current_hull: float = 100.0
var fire_cooldown_remaining: float = 0.0

@onready var weapon_muzzle: Marker2D = $WeaponMuzzle

func _ready() -> void:
	current_hull = max_hull

func _physics_process(delta: float) -> void:
	var turn_input: float = Input.get_axis("move_left", "move_right")

	if turn_input != 0.0:
		rotation += turn_input * turn_speed * delta

	var forward_direction: Vector2 = Vector2.RIGHT.rotated(rotation)

	if Input.is_action_pressed("move_up"):
		velocity += forward_direction * forward_acceleration * delta

	if Input.is_action_pressed("move_down"):
		velocity = velocity.move_toward(
			Vector2.ZERO,
			braking_acceleration * delta
		)

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	move_and_slide()

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
		var aim_direction: Vector2 = get_global_mouse_position() - weapon_muzzle.global_position

		if aim_direction.length_squared() <= 0.0:
			return

		projectile_2d.global_position = weapon_muzzle.global_position
		projectile_2d.global_rotation = aim_direction.angle()
		projectile_2d.set("owner_group", "player_projectile")
		get_tree().current_scene.add_child(projectile_2d)
		fire_cooldown_remaining = primary_fire_cooldown

func take_damage(damage_amount: float) -> void:
	current_hull = maxf(0.0, current_hull - damage_amount)
	if current_hull <= 0.0:
		queue_free()
