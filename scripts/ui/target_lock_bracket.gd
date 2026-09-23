class_name TargetLockBracket
extends Control

## Screen-space bracket for the player's current target.
##
## This component only reads the player's TargetingSystem. It does not choose,
## lock or cycle targets. The bracket follows the projected bounds of the
## current target and fades toward the screen edge as the direction indicator
## takes over.

@export var ship_path: NodePath
@export var screen_margin: float = 32.0
@export var transition_margin: float = 120.0
@export var padding: float = 12.0
@export var corner_length: float = 18.0
@export var line_width: float = 2.0

var ship: Ship
var targeting_system: TargetingSystem


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship = get_node_or_null(ship_path) as Ship

	if ship != null:
		targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem

	visible = false
	set_process(true)


func _process(_delta: float) -> void:
	_update_bracket()


func _update_bracket() -> void:
	visible = false
	modulate.a = 0.0

	if targeting_system == null:
		return

	var target_node: Node3D = targeting_system.get_target()

	if target_node == null or not is_instance_valid(target_node):
		return

	var target_ship: Ship = target_node as Ship

	if target_ship != null and target_ship.is_destroyed():
		return

	var camera: Camera3D = get_viewport().get_camera_3d()

	if camera == null or camera.is_position_behind(target_node.global_position):
		return

	var projected_bounds: Rect2 = _get_projected_bounds(camera, target_node)

	if projected_bounds.size.x <= 0.0 or projected_bounds.size.y <= 0.0:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_rect: Rect2 = Rect2(
		Vector2(screen_margin, screen_margin),
		viewport_size - Vector2(screen_margin * 2.0, screen_margin * 2.0)
	)

	var target_screen_position: Vector2 = camera.unproject_position(target_node.global_position)
	var bracket_alpha: float = _get_bracket_alpha(target_screen_position, screen_rect)

	if bracket_alpha <= 0.0:
		return

	var bracket_rect: Rect2 = projected_bounds.grow(padding)
	bracket_rect.position.x = clampf(
		bracket_rect.position.x,
		screen_rect.position.x,
		maxf(screen_rect.end.x - bracket_rect.size.x, screen_rect.position.x)
	)
	bracket_rect.position.y = clampf(
		bracket_rect.position.y,
		screen_rect.position.y,
		maxf(screen_rect.end.y - bracket_rect.size.y, screen_rect.position.y)
	)
	bracket_rect.size.x = minf(bracket_rect.size.x, screen_rect.size.x)
	bracket_rect.size.y = minf(bracket_rect.size.y, screen_rect.size.y)

	position = bracket_rect.position
	size = bracket_rect.size
	modulate.a = bracket_alpha
	visible = true
	queue_redraw()


func _get_bracket_alpha(target_position: Vector2, safe_rect: Rect2) -> float:
	if not safe_rect.grow(transition_margin).has_point(target_position):
		return 0.0

	if safe_rect.has_point(target_position):
		var distance_to_edge: float = minf(
			minf(
				target_position.x - safe_rect.position.x,
				safe_rect.end.x - target_position.x
			),
			minf(
				target_position.y - safe_rect.position.y,
				safe_rect.end.y - target_position.y
			)
		)

		return clampf(distance_to_edge / transition_margin, 0.0, 1.0)

	return 0.0


func _get_projected_bounds(camera: Camera3D, target_node: Node3D) -> Rect2:
	var points: Array[Vector3] = []

	var target_ship: Ship = target_node as Ship

	if target_ship != null and target_ship.ship_data != null:
		var half_extents: Vector3 = target_ship.ship_data.dimensions * 0.5

		for x: float in [-half_extents.x, half_extents.x]:
			for y: float in [-half_extents.y, half_extents.y]:
				for z: float in [-half_extents.z, half_extents.z]:
					points.append(
						target_ship.global_transform * Vector3(x, y, z)
					)

	else:
		points.append(target_node.global_position)

	var first_point: Vector2 = camera.unproject_position(points[0])
	var min_point: Vector2 = first_point
	var max_point: Vector2 = first_point

	for point: Vector3 in points:
		var screen_point: Vector2 = camera.unproject_position(point)
		min_point.x = minf(min_point.x, screen_point.x)
		min_point.y = minf(min_point.y, screen_point.y)
		max_point.x = maxf(max_point.x, screen_point.x)
		max_point.y = maxf(max_point.y, screen_point.y)

	return Rect2(min_point, max_point - min_point)


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	var top_left: Vector2 = rect.position
	var top_right: Vector2 = Vector2(rect.end.x, rect.position.y)
	var bottom_left: Vector2 = Vector2(rect.position.x, rect.end.y)
	var bottom_right: Vector2 = rect.end

	var color: Color = Color(0.2, 0.85, 1.0, 0.95)

	# Top-left
	draw_line(top_left, top_left + Vector2(corner_length, 0.0), color, line_width)
	draw_line(top_left, top_left + Vector2(0.0, corner_length), color, line_width)

	# Top-right
	draw_line(top_right, top_right + Vector2(-corner_length, 0.0), color, line_width)
	draw_line(top_right, top_right + Vector2(0.0, corner_length), color, line_width)

	# Bottom-left
	draw_line(bottom_left, bottom_left + Vector2(corner_length, 0.0), color, line_width)
	draw_line(bottom_left, bottom_left + Vector2(0.0, -corner_length), color, line_width)

	# Bottom-right
	draw_line(bottom_right, bottom_right + Vector2(-corner_length, 0.0), color, line_width)
	draw_line(bottom_right, bottom_right + Vector2(0.0, -corner_length), color, line_width)
