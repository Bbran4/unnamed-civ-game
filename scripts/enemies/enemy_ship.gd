extends CharacterBody2D

@export var move_speed: float = 130.0
@export var acceleration: float = 500.0
@export var max_hull: float = 50.0
@export var preferred_distance: float = 300.0
@export var fire_cooldown: float = 0.8
@export var projectile_scene: PackedScene

var current_hull: float = 50.0
var fire_cooldown_remaining: float = 0.0
var player_ship: Node2D

@onready var weapon_muzzle: Marker2D = $WeaponMuzzle

func _ready() -> void:
	current_hull = max_hull
	player_ship = get_tree().get_first_node_in_group("player_ship") as Node2D

func _physics_process(delta: float) -> void:
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
	current_hull = maxf(0.0, current_hull - damage_amount)
	if current_hull <= 0.0:
		queue_free()
