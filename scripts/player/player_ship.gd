extends CharacterBody2D

@export var move_speed: float = 280.0
@export var acceleration: float = 1400.0
@export var max_hull: float = 100.0
@export var primary_fire_cooldown: float = 0.18
@export var projectile_scene: PackedScene

var current_hull: float = 100.0
var fire_cooldown_remaining: float = 0.0

@onready var weapon_muzzle: Marker2D = $WeaponMuzzle

func _ready() -> void:
	current_hull = max_hull

func _physics_process(delta: float) -> void:
	var aim_direction: Vector2 = get_global_mouse_position() - global_position
	if aim_direction.length_squared() > 0.0:
		rotation = aim_direction.angle()

	var movement_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward_direction: Vector2 = Vector2.RIGHT.rotated(rotation)
	var right_direction: Vector2 = forward_direction.rotated(PI * 0.5)
	var movement_direction: Vector2 = (forward_direction * -movement_input.y) + (right_direction * movement_input.x)
	var target_velocity: Vector2 = movement_direction * move_speed

	velocity = velocity.move_toward(target_velocity, acceleration * delta)
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
		projectile_2d.global_position = weapon_muzzle.global_position
		projectile_2d.global_rotation = global_rotation
		projectile_2d.set("owner_group", "player_projectile")
		get_tree().current_scene.add_child(projectile_2d)
		fire_cooldown_remaining = primary_fire_cooldown

func take_damage(damage_amount: float) -> void:
	current_hull = maxf(0.0, current_hull - damage_amount)
	if current_hull <= 0.0:
		queue_free()
