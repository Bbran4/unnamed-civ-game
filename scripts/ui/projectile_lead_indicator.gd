class_name ProjectileLeadIndicator
extends Control

## Screen-space lead indicator for the player's currently locked target.
##
## The indicator solves a simple projectile interception problem using the
## actual projectile speed and the target's current velocity. It shows the
## point where the target is expected to be when the projectile arrives.
##
## The player fires through the camera centre, so bringing the crosshair onto
## this circle aligns the actual projectile with the predicted intercept point.

@export var ship_path: NodePath
@export var radius: float = 14.0
@export var line_width: float = 2.0
@export var point_count: int = 32

var ship: Ship
var targeting_system: TargetingSystem
var lead_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship = get_node_or_null(ship_path) as Ship

	if ship != null:
		targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem

	visible = false
	set_process(true)


func _process(_delta: float) -> void:
	_update_indicator()


func _update_indicator() -> void:
	visible = false

	if ship == null or targeting_system == null:
		return

	var target: Ship = targeting_system.get_target() as Ship

	if target == null or target.is_destroyed():
		return

	var weapon: Weapon = ship.get_weapon(0)

	if weapon == null or weapon.weapon_data == null:
		return

	if weapon.weapon_data.projectile_data == null:
		return

	var projectile_speed: float = weapon.weapon_data.projectile_data.speed_mps

	if projectile_speed <= 0.0:
		return

	var camera: Camera3D = get_viewport().get_camera_3d()

	if camera == null:
		return

	var intercept_position: Vector3 = _calculate_intercept_position(
		weapon.muzzle.global_position,
		target,
		projectile_speed
	)

	if intercept_position == Vector3.INF:
		return

	if camera.is_position_behind(intercept_position):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var projected_position: Vector2 = camera.unproject_position(intercept_position)

	if projected_position.x < 0.0 or projected_position.x > viewport_size.x:
		return

	if projected_position.y < 0.0 or projected_position.y > viewport_size.y:
		return

	position = projected_position
	size = Vector2.ZERO
	lead_position = projected_position
	visible = true
	queue_redraw()


func _calculate_intercept_position(
	muzzle_position: Vector3,
	target: Ship,
	projectile_speed: float
) -> Vector3:
	var relative_position: Vector3 = target.global_position - muzzle_position
	var target_velocity: Vector3 = target.velocity

	var a: float = target_velocity.dot(target_velocity) - projectile_speed * projectile_speed
	var b: float = 2.0 * relative_position.dot(target_velocity)
	var c: float = relative_position.dot(relative_position)

	var intercept_time: float = -1.0

	if absf(a) < 0.0001:
		if absf(b) > 0.0001:
			var linear_time: float = -c / b

			if linear_time > 0.0:
				intercept_time = linear_time
	else:
		var discriminant: float = b * b - 4.0 * a * c

		if discriminant >= 0.0:
			var sqrt_discriminant: float = sqrt(discriminant)
			var time_a: float = (-b - sqrt_discriminant) / (2.0 * a)
			var time_b: float = (-b + sqrt_discriminant) / (2.0 * a)

			if time_a > 0.0:
				intercept_time = time_a

			if time_b > 0.0 and (intercept_time <= 0.0 or time_b < intercept_time):
				intercept_time = time_b

	if intercept_time <= 0.0:
		# A static target, or a target with no mathematically reachable
		# interception point, falls back to its current position only when it is
		# effectively stationary. Otherwise there is no useful lead solution.
		if target_velocity.length_squared() <= 0.0001:
			return target.global_position

		return Vector3.INF

	return target.global_position + target_velocity * intercept_time


func _draw() -> void:
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		maxi(point_count, 8),
		Color(0.2, 0.85, 1.0, 0.85),
		line_width,
		true
	)
