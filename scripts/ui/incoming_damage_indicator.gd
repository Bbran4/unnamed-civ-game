class_name IncomingDamageIndicator
extends Control

## Temporary directional damage feedback around the player's HUD.
##
## The component listens to the player's existing damage_received signal. The
## damage source is projected into the camera's 2D view and shown as a red arc
## around the screen centre. It does not modify damage or combat behaviour.

@export var ship_path: NodePath
@export var radius: float = 115.0
@export var arc_half_angle_degrees: float = 32.0
@export var arc_width: float = 5.0
@export var display_duration: float = 0.65
@export var fade_out_duration: float = 0.25
@export var point_count: int = 20

var ship: Ship
var damage_time_remaining: float = 0.0
var damage_direction: Vector2 = Vector2.UP


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship = get_node_or_null(ship_path) as Ship

	if ship != null:
		ship.damage_received.connect(_on_ship_damage_received)

	visible = false
	set_process(true)


func _exit_tree() -> void:
	if ship != null and ship.damage_received.is_connected(_on_ship_damage_received):
		ship.damage_received.disconnect(_on_ship_damage_received)


func _process(delta: float) -> void:
	if damage_time_remaining <= 0.0:
		if visible:
			visible = false
			queue_redraw()
		return

	damage_time_remaining = maxf(damage_time_remaining - delta, 0.0)
	visible = true
	queue_redraw()


func _on_ship_damage_received(
	_amount: float,
	source: Node,
	_remaining_hull: float
) -> void:
	if ship == null or source == null or not is_instance_valid(source):
		return

	var source_node: Node3D = source as Node3D

	if source_node == null:
		return

	var incoming_direction: Vector3 = source_node.global_position - ship.global_position

	if incoming_direction.length_squared() <= 0.0001:
		return

	incoming_direction = incoming_direction.normalized()

	var camera: Camera3D = get_viewport().get_camera_3d()

	if camera != null:
		var camera_local_direction: Vector3 = (
			camera.global_transform.basis.inverse() * incoming_direction
		)
		damage_direction = Vector2(
			camera_local_direction.x,
			camera_local_direction.z
		)

		# A hit directly above or below has no horizontal screen direction.
		# In that case, use the vertical camera direction so the indicator still
		# provides useful feedback.
		if damage_direction.length_squared() <= 0.0001:
			damage_direction = Vector2(
			0.0,
			-camera_local_direction.y
		)
	else:
		var ship_local_direction: Vector3 = (
			ship.global_transform.basis.inverse() * incoming_direction
		)
		damage_direction = Vector2(
			ship_local_direction.x,
			ship_local_direction.z
		)

	if damage_direction.length_squared() <= 0.0001:
		damage_direction = Vector2.UP
	else:
		damage_direction = damage_direction.normalized()

	damage_time_remaining = maxf(display_duration, 0.0)
	visible = true
	queue_redraw()


func _draw() -> void:
	if damage_time_remaining <= 0.0:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var centre: Vector2 = viewport_size * 0.5

	var fade_start: float = minf(fade_out_duration, display_duration)
	var fade_alpha: float = 1.0

	if fade_start > 0.0 and damage_time_remaining < fade_start:
		fade_alpha = damage_time_remaining / fade_start

	var arc_half_angle: float = deg_to_rad(arc_half_angle_degrees)
	var direction_angle: float = damage_direction.angle()
	var start_angle: float = direction_angle - arc_half_angle
	var end_angle: float = direction_angle + arc_half_angle

	var indicator_color: Color = Color(
		1.0,
		0.08,
		0.06,
		0.9 * fade_alpha
	)

	draw_arc(
		centre,
		radius,
		start_angle,
		end_angle,
		maxi(point_count, 4),
		indicator_color,
		arc_width,
		true
	)
