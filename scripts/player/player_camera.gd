extends Camera2D

@export var normal_zoom: float = 1.0
@export var boost_zoom: float = 0.62
@export var zoom_response: float = 5.0
@export var shake_decay: float = 10.0

var shake_strength: float = 0.0

func _ready() -> void:
	zoom = Vector2(normal_zoom, normal_zoom)

func _process(delta: float) -> void:
	shake_strength = maxf(0.0, shake_strength - shake_decay * delta)

	if shake_strength > 0.0:
		var shake_offset: Vector2 = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		offset = shake_offset
	else:
		offset = Vector2.ZERO

func update_speed_zoom(boost_active: bool, delta: float) -> void:
	var target_zoom_value: float = normal_zoom

	if boost_active:
		target_zoom_value = boost_zoom

	var target_zoom: Vector2 = Vector2(target_zoom_value, target_zoom_value)
	var zoom_weight: float = minf(1.0, delta * zoom_response)
	zoom = zoom.lerp(target_zoom, zoom_weight)

func shake(duration: float, strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)
