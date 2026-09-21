extends Area2D

@export var credit_value: int = 50

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player_ship"):
		return

	WorldState.credits += credit_value
	queue_free()
