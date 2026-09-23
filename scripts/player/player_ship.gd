extends CharacterBody3D

## Milestone 1: basic 3D space flight.
## Arcade-like acceleration and momentum, designed to become the foundation
## for combat and exploration.

@export_category("Flight")
@export var max_speed: float = 35.0
@export var reverse_speed: float = 12.0
@export var acceleration: float = 18.0
@export var brake_strength: float = 28.0
@export var boost_speed: float = 65.0
@export var boost_acceleration: float = 35.0

@export_category("Rotation")
@export var mouse_sensitivity: float = 0.0025
@export var keyboard_pitch_speed: float = 1.2
@export var keyboard_yaw_speed: float = 1.4
@export var roll_speed: float = 1.8

@export_category("Strafe")
@export var strafe_speed: float = 14.0

var throttle: float = 0.0
var mouse_input := Vector2.ZERO
var boost_active := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input += event.relative

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	_apply_rotation(delta)
	_apply_throttle(delta)
	_apply_translation(delta)
	move_and_slide()

func _apply_rotation(delta: float) -> void:
	var mouse_pitch := -mouse_input.y * mouse_sensitivity
	var mouse_yaw := -mouse_input.x * mouse_sensitivity
	mouse_input = Vector2.ZERO

	# All pilot controls rotate around the ship's local axes.
	# This keeps mouse/keyboard yaw consistent even after rolling 180 degrees.
	rotate_object_local(Vector3.RIGHT, mouse_pitch)
	rotate_object_local(Vector3.UP, mouse_yaw)

	var pitch := _axis(KEY_DOWN, KEY_UP)
	var yaw := _axis(KEY_LEFT, KEY_RIGHT)
	var roll := _axis(KEY_Q, KEY_E)

	rotate_object_local(Vector3.RIGHT, pitch * keyboard_pitch_speed * delta)
	rotate_object_local(Vector3.UP, yaw * keyboard_yaw_speed * delta)
	rotate_object_local(Vector3.FORWARD, roll * roll_speed * delta)

	# Re-orthonormalize after repeated rotations to prevent floating-point drift
	# from turning the transform basis into a non-rotation matrix.
	global_basis = global_basis.orthonormalized()

func _apply_throttle(delta: float) -> void:
	var throttle_input := _axis(KEY_S, KEY_W)
	throttle = clamp(throttle + throttle_input * delta, -1.0, 1.0)

	if Input.is_key_pressed(KEY_SPACE):
		throttle = move_toward(throttle, 0.0, 3.0 * delta)

	boost_active = Input.is_key_pressed(KEY_SHIFT) and throttle > 0.0

func _apply_translation(delta: float) -> void:
	var target_speed := throttle * max_speed

	if boost_active:
		target_speed = boost_speed

	if throttle < 0.0:
		target_speed = throttle * reverse_speed

	var forward := -global_transform.basis.z
	var desired_forward_velocity := forward * target_speed
	var current_forward := velocity.project(forward)

	var rate := acceleration
	if abs(target_speed) < 0.01:
		rate = brake_strength
	elif boost_active:
		rate = boost_acceleration

	velocity += (desired_forward_velocity - current_forward).limit_length(rate * delta)

	var strafe := _axis(KEY_A, KEY_D)
	velocity += global_transform.basis.x * strafe * strafe_speed * delta

func _axis(negative_key: Key, positive_key: Key) -> float:
	return float(Input.is_key_pressed(positive_key)) - float(Input.is_key_pressed(negative_key))

func get_speed() -> float:
	return velocity.length()

func get_throttle_percent() -> float:
	return throttle
