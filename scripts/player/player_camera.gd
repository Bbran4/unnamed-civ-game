extends Camera2D

@export var normal_zoom: float = 1.0
@export var boost_zoom: float = 0.62
@export var zoom_transition_duration: float = 2.0
@export var shake_decay: float = 10.0

var shake_strength: float = 0.0
var zoom_transition: float = 0.0

func _ready() -> void:
	zoom = Vector2(normal_zoom, normal_zoom)
	zoom_transition = 0.0

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
	var target_transition: float = 0.0

	if boost_active:
		target_transition = 1.0

	var transition_speed: float = 1.0 / zoom_transition_duration
	zoom_transition = move_toward(zoom_transition, target_transition, transition_speed * delta)

	var eased_transition: float = smoothstep(0.0, 1.0, zoom_transition)
	var current_zoom_value: float = lerpf(normal_zoom, boost_zoom, eased_transition)
	zoom = Vector2(current_zoom_value, current_zoom_value)

func shake(_duration: float, strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)
