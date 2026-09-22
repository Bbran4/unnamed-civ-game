class_name Asteroid
extends Area2D

@export var collision_damage: float = 20.0
@export var collision_cooldown: float = 0.75

var collision_cooldown_remaining: float = 0.0

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    collision_cooldown_remaining = maxf(0.0, collision_cooldown_remaining - delta)

func _on_body_entered(body: Node2D) -> void:
    if collision_cooldown_remaining > 0.0:
        return

    if not body.is_in_group("player_ship"):
        return

    if not body.has_method("take_damage"):
        return

    body.call("take_damage", collision_damage, "kinetic", 1.0, 1.0)
    collision_cooldown_remaining = collision_cooldown
