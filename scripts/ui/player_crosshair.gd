class_name PlayerCrosshair
extends Control

## Graphical mouse-aim crosshair.
##
## The crosshair follows the player's actual mouse cursor. The ship controller
## uses that same screen position as its steering target, keeping the HUD and
## flight controls visually consistent.

@export var crosshair_size: float = 42.0
@export var centre_gap: float = 8.0
@export var segment_length: float = 10.0
@export var line_width: float = 2.0

var crosshair_color: Color = Color(0.2, 0.85, 1.0, 0.95)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var centre: Vector2 = get_local_mouse_position()
	var half_gap: float = centre_gap * 0.5
	var half_size: float = crosshair_size * 0.5
	var half_segment: float = segment_length

	# Top
	draw_line(
		centre + Vector2(0.0, -half_gap),
		centre + Vector2(0.0, -half_gap - half_segment),
		crosshair_color,
		line_width
	)

	# Bottom
	draw_line(
		centre + Vector2(0.0, half_gap),
		centre + Vector2(0.0, half_gap + half_segment),
		crosshair_color,
		line_width
	)

	# Left
	draw_line(
		centre + Vector2(-half_gap, 0.0),
		centre + Vector2(-half_gap - half_segment, 0.0),
		crosshair_color,
		line_width
	)

	# Right
	draw_line(
		centre + Vector2(half_gap, 0.0),
		centre + Vector2(half_gap + half_segment, 0.0),
		crosshair_color,
		line_width
	)
