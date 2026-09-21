extends Camera2D

@export var normal_zoom: float = 1.0
@export var speed_zoom_out: float = 0.78
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

func update_speed_zoom(speed: float, current_max_speed: float) -> void:
	var speed_ratio: float = 0.0

	if current_max_speed > 0.0:
		speed_ratio = clampf(speed / current_max_speed, 0.0, 1.0)

	var target_zoom_value: float = lerpf(normal_zoom, speed_zoom_out, speed_ratio)
	var target_zoom: Vector2 = Vector2(target_zoom_value, target_zoom_value)
	zoom = zoom.lerp(target_zoom, get_process_delta_time() * zoom_response)

func shake(duration: float, strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)
