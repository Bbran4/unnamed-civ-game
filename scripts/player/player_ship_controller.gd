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

@export_category("Mouse")
@export var mouse_sensitivity: float = 0.04

@export_category("Camera")
@export var camera_path: NodePath = NodePath("../Camera3D")
## Distance in metres used to construct the free-aim point when no target is locked.
@export var free_aim_distance: float = 1000.0

@export_category("Targeting")
## Maximum distance in metres used when locking or cycling targets.
@export var target_cycle_range: float = 1500.0

var mouse_input: Vector2 = Vector2.ZERO
var targeting_system: TargetingSystem
var camera: Camera3D


func _ready() -> void:
	super._ready()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if ship != null:
		targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem
		camera = get_node_or_null(camera_path) as Camera3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input += event.relative

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_T:
			_cycle_target()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func get_flight_intent(_delta: float) -> Dictionary:
	var intent := super.get_flight_intent(_delta)

	var mouse_pitch: float = clampf(-mouse_input.y * mouse_sensitivity, -1.0, 1.0)
	var mouse_yaw: float = clampf(-mouse_input.x * mouse_sensitivity, -1.0, 1.0)
	mouse_input = Vector2.ZERO

	intent["pitch"] = mouse_pitch + _axis(KEY_DOWN, KEY_UP)
	intent["yaw"] = mouse_yaw + _axis(KEY_LEFT, KEY_RIGHT)
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


func _get_fire_direction() -> Vector3:
	if camera == null:
		return Vector3.ZERO

	var weapon: Weapon = ship.get_weapon(0)

	if weapon == null or weapon.muzzle == null:
		return Vector3.ZERO

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var crosshair_position: Vector2 = viewport_size * 0.5
	var aim_distance: float = maxf(free_aim_distance, 1.0)

	if targeting_system != null:
		var target: Node3D = targeting_system.get_target()

		if target != null:
			var target_distance: float = targeting_system.get_target_distance()

			if target_distance > 1.0 and target_distance < 100000.0:
				aim_distance = target_distance

	# project_position() gives us a world-space point exactly on the camera's
	# crosshair ray at the chosen depth. The projectile then travels from the
	# physical muzzle toward that point, eliminating the camera/muzzle parallax
	# that made shots appear below the crosshair.
	var aim_point: Vector3 = camera.project_position(
		crosshair_position,
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
