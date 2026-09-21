extends Area2D

@export var speed: float = 700.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0

var owner_group: String = ""
var lifetime_remaining: float = 2.0

func _ready() -> void:
	lifetime_remaining = lifetime
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(global_rotation) * speed * delta
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if owner_group == "player_projectile" and body.is_in_group("enemy_ship"):
		body.call("take_damage", damage)
		queue_free()
	elif owner_group == "enemy_projectile" and body.is_in_group("player_ship"):
		body.call("take_damage", damage)
		queue_free()
