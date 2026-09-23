class_name TargetLockBracket
extends Control

## Screen-space bracket for the player's current target.
##
## This component only reads the player's TargetingSystem. It does not choose,
## lock or cycle targets. The bracket follows the projected bounds of the
## current target while it remains visible to the camera.

@export var ship_path: NodePath
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

	set_process(true)
	visible = false


func _process(_delta: float) -> void:
	_update_bracket()


func _update_bracket() -> void:
	visible = false

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
	var screen_rect: Rect2 = Rect2(Vector2.ZERO, viewport_size)

	if not screen_rect.intersects(projected_bounds):
		return

	var bracket_rect: Rect2 = projected_bounds.grow(padding)
	bracket_rect.position.x = clampf(bracket_rect.position.x, 0.0, maxf(viewport_size.x - bracket_rect.size.x, 0.0))
	bracket_rect.position.y = clampf(bracket_rect.position.y, 0.0, maxf(viewport_size.y - bracket_rect.size.y, 0.0))
	bracket_rect.size.x = minf(bracket_rect.size.x, viewport_size.x)
	bracket_rect.size.y = minf(bracket_rect.size.y, viewport_size.y)

	position = bracket_rect.position
	size = bracket_rect.size
	visible = true
	queue_redraw()


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
