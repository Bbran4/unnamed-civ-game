extends Area2D

@export var speed: float = 1400.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0
@export var projectile_type: String = "energy"
@export var shield_damage_multiplier: float = 1.0
@export var hull_damage_multiplier: float = 1.0
@export var tracking: bool = false
@export var tracking_turn_speed: float = 3.0

var owner_group: String = ""
var lifetime_remaining: float = 2.0
var target: Node2D

func _ready() -> void:
	lifetime_remaining = lifetime
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if tracking and is_instance_valid(target):
		var direction_to_target: Vector2 = global_position.direction_to(target.global_position)
		var current_direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)
		var turn_amount: float = tracking_turn_speed * delta
		var angle_difference: float = current_direction.angle_to(direction_to_target)
		var limited_angle: float = clampf(angle_difference, -turn_amount, turn_amount)
		global_rotation += limited_angle

	global_position += Vector2.RIGHT.rotated(global_rotation) * speed * delta
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if owner_group == "player_projectile" and body.is_in_group("enemy_ship"):
		body.call("take_damage", damage, projectile_type, shield_damage_multiplier, hull_damage_multiplier)
		queue_free()
	elif owner_group == "enemy_projectile" and body.is_in_group("player_ship"):
		body.call("take_damage", damage)
		queue_free()
