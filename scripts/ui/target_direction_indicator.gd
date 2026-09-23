class_name TargetDirectionIndicator
extends Control

## Screen-edge arrow for the player's current target.
##
## The indicator only reads TargetingSystem state. It does not select or lock
## targets. When the target is outside the camera view, the arrow is clamped
## to a safe screen margin and rotated to point toward the target.

@export var ship_path: NodePath
@export var screen_margin: float = 42.0
@export var arrow_size: float = 16.0
@export var line_width: float = 2.0

var ship: Ship
var targeting_system: TargetingSystem
var arrow_rotation: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship = get_node_or_null(ship_path) as Ship

	if ship != null:
		targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem

	visible = false
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	_update_indicator()


func _update_indicator() -> void:
	visible = false

	if targeting_system == null:
		return

	var target: Node3D = targeting_system.get_target()

	if target == null or not is_instance_valid(target):
		return

	var target_ship: Ship = target as Ship

	if target_ship != null and target_ship.is_destroyed():
		return

	var camera: Camera3D = get_viewport().get_camera_3d()

	if camera == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = viewport_size * 0.5
	var target_camera_position: Vector3 = camera.global_transform.affine_inverse() * target.global_position

	# The target direction on screen uses camera-local X for horizontal and
	# inverse camera-local Y for vertical. A target behind the camera is flipped
	# so its indicator still points toward the correct side of the screen.
	var screen_direction: Vector2 = Vector2(
		target_camera_position.x,
		-target_camera_position.y
	)

	if target_camera_position.z > 0.0:
		screen_direction = -screen_direction

	if screen_direction.length_squared() <= 0.0001:
		return

	screen_direction = screen_direction.normalized()

	var projected_target: Vector2 = camera.unproject_position(target.global_position)
	var inside_screen: bool = (
		projected_target.x >= 0.0
		and projected_target.x <= viewport_size.x
		and projected_target.y >= 0.0
		and projected_target.y <= viewport_size.y
		and target_camera_position.z < 0.0
	)

	if inside_screen:
		return

	var safe_rect: Rect2 = Rect2(
		Vector2(screen_margin, screen_margin),
		viewport_size - Vector2(screen_margin * 2.0, screen_margin * 2.0)
	)

	var edge_center: Vector2 = _intersect_center_ray_with_rect(
		center,
		screen_direction,
		safe_rect
	)

	position = edge_center
	size = Vector2.ZERO
	arrow_rotation = screen_direction.angle()
	visible = true
	queue_redraw()


func _intersect_center_ray_with_rect(
	center: Vector2,
	direction: Vector2,
	rect: Rect2
) -> Vector2:
	var candidates: Array[float] = []

	if absf(direction.x) > 0.0001:
		candidates.append((rect.position.x - center.x) / direction.x)
		candidates.append((rect.end.x - center.x) / direction.x)

	if absf(direction.y) > 0.0001:
		candidates.append((rect.position.y - center.y) / direction.y)
		candidates.append((rect.end.y - center.y) / direction.y)

	var nearest_distance: float = INF

	for distance: float in candidates:
		if distance <= 0.0 or distance >= nearest_distance:
			continue

		var point: Vector2 = center + direction * distance

		if rect.grow(0.5).has_point(point):
			nearest_distance = distance

	if nearest_distance == INF:
		return center

	return center + direction * nearest_distance


func _draw() -> void:
	var direction: Vector2 = Vector2.RIGHT.rotated(arrow_rotation)
	var side_direction: Vector2 = Vector2(-direction.y, direction.x)

	var tip: Vector2 = direction * arrow_size
	var left: Vector2 = -direction * arrow_size * 0.45 + side_direction * arrow_size * 0.65
	var right: Vector2 = -direction * arrow_size * 0.45 - side_direction * arrow_size * 0.65

	var fill_color: Color = Color(1.0, 0.12, 0.08, 0.95)
	var outline_color: Color = Color(1.0, 0.45, 0.35, 0.95)

	draw_colored_polygon(PackedVector2Array([tip, left, right]), fill_color)
	draw_polyline(
		PackedVector2Array([tip, left, right, tip]),
		outline_color,
		line_width
	)
