class_name PlayerCrosshair
extends Control

## Graphical flight crosshair.
##
## The crosshair is purely presentation. It stays centered on the HUD and
## leaves an open centre so future targeting aids, such as the projectile lead
## indicator, can occupy the same space without obscuring the reticle.

@export var crosshair_size: float = 42.0
@export var centre_gap: float = 8.0
@export var segment_length: float = 10.0
@export var line_width: float = 2.0

var crosshair_color: Color = Color(0.2, 0.85, 1.0, 0.95)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER)
	size = Vector2(crosshair_size, crosshair_size)
	pivot_offset = size * 0.5
	queue_redraw()


func _draw() -> void:
	var centre: Vector2 = size * 0.5
	var half_gap: float = centre_gap * 0.5

	# Top
	draw_line(
		centre + Vector2(0.0, -half_gap),
		centre + Vector2(0.0, -half_gap - segment_length),
		crosshair_color,
		line_width
	)

	# Bottom
	draw_line(
		centre + Vector2(0.0, half_gap),
		centre + Vector2(0.0, half_gap + segment_length),
		crosshair_color,
		line_width
	)

	# Left
	draw_line(
		centre + Vector2(-half_gap, 0.0),
		centre + Vector2(-half_gap - segment_length, 0.0),
		crosshair_color,
		line_width
	)

	# Right
	draw_line(
		centre + Vector2(half_gap, 0.0),
		centre + Vector2(half_gap + segment_length, 0.0),
		crosshair_color,
		line_width
	)
