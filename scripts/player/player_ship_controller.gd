class_name PlayerShipController
extends ShipController

## Player input controller.
##
## Converts mouse and keyboard input into flight and targeting intent.
## The Ship remains responsible for interpreting flight intent and applying
## movement, acceleration, braking and rotation.
##
## Target selection is handled here at the input layer. TargetingSystem owns
## candidate discovery and the current target state.

@export_category("Mouse Aim")
## Maximum angular offset, in degrees, represented by the cursor.
@export var max_cursor_angle_degrees: float = 28.0
## Scales the cursor's requested turn rate. Lower values produce a slower,
## more deliberate ship response.
@export var cursor_steering_strength: float = 0.08
## Small cursor deadzone around the screen centre.
@export var cursor_deadzone_pixels: float = 3.0

@export_category("Camera")
@export var camera_path: NodePath = NodePath("../Camera3D")
## Distance in metres used to construct the free-aim point when no target is locked.
@export var free_aim_distance: float = 1000.0

@export_category("Targeting")
## Maximum distance in metres used when locking or cycling targets.
@export var target_cycle_range: float = 1500.0

var targeting_system: TargetingSystem
var camera: Camera3D


func _ready() -> void:
	super._ready()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	if ship != null:
		targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem
		camera = get_node_or_null(camera_path) as Camera3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_T:
			_cycle_target()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func get_flight_intent(_delta: float) -> Dictionary:
	var intent := super.get_flight_intent(_delta)

	var cursor_input: Vector2 = _get_cursor_steering_input()

	intent["pitch"] = cursor_input.x + _axis(KEY_DOWN, KEY_UP)
	intent["yaw"] = cursor_input.y + _axis(KEY_LEFT, KEY_RIGHT)
	intent["roll"] = _axis(KEY_Q, KEY_E)
	intent["strafe"] = _axis(KEY_A, KEY_D)
	intent["throttle"] = _axis(KEY_S, KEY_W)
	intent["brake"] = Input.is_key_pressed(KEY_SPACE)
	intent["boost"] = Input.is_key_pressed(KEY_SHIFT)
	intent["fire"] = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	var fire_direction: Vector3 = _get_fire_direction()
	if fire_direction != Vector3.ZERO:
		intent["fire_direction"] = fire_direction

	return intent


func _get_cursor_steering_input() -> Vector2:
	if camera == null or ship == null:
		return Vector2.ZERO

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var cursor_position: Vector2 = get_viewport().get_mouse_position()
	var centre: Vector2 = viewport_size * 0.5
	var cursor_offset: Vector2 = cursor_position - centre

	if cursor_offset.length() <= maxf(cursor_deadzone_pixels, 0.0):
		return Vector2.ZERO

	var aim_ray: Vector3 = camera.project_ray_normal(cursor_position)
	var local_direction: Vector3 = (
		ship.global_transform.basis.orthonormalized().inverse() * aim_ray
	).normalized()

	if local_direction.length_squared() <= 0.0001:
		return Vector2.ZERO

	# Ship forward is -Z. Positive yaw turns the nose left in this flight model,
	# so horizontal cursor movement uses the opposite sign.
	var yaw_angle: float = atan2(local_direction.x, -local_direction.z)
	var pitch_angle: float = atan2(local_direction.y, -local_direction.z)
	var max_angle: float = deg_to_rad(maxf(max_cursor_angle_degrees, 1.0))

	var pitch_input: float = clampf(pitch_angle / max_angle, -1.0, 1.0)
	var yaw_input: float = -clampf(yaw_angle / max_angle, -1.0, 1.0)

	return Vector2(
		pitch_input * cursor_steering_strength,
		yaw_input * cursor_steering_strength
	)


func _get_fire_direction() -> Vector3:
	if camera == null:
		return Vector3.ZERO

	var weapon: Weapon = ship.get_weapon(0)

	if weapon == null or weapon.muzzle == null:
		return Vector3.ZERO

	var cursor_position: Vector2 = get_viewport().get_mouse_position()
	var aim_distance: float = maxf(free_aim_distance, 1.0)

	if targeting_system != null:
		var target: Node3D = targeting_system.get_target()

		if target != null:
			var target_camera_distance: float = camera.global_position.distance_to(
				target.global_position
			)

			if target_camera_distance > 1.0 and target_camera_distance < 100000.0:
				aim_distance = target_camera_distance

	# Build a world-space point on the same ray as the on-screen cursor.
	# The physical muzzle then aims toward that point, removing camera/muzzle
	# parallax while preserving free cursor aiming.
	var aim_point: Vector3 = camera.project_position(
		cursor_position,
		aim_distance
	)

	return (aim_point - weapon.muzzle.global_position).normalized()


func _cycle_target() -> void:
	if targeting_system == null:
		return

	var target: Ship = targeting_system.cycle_target(target_cycle_range)

	if target == null:
		return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _axis(negative_key: Key, positive_key: Key) -> float:
	return float(Input.is_key_pressed(positive_key)) - float(Input.is_key_pressed(negative_key))
