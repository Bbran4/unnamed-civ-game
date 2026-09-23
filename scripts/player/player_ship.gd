extends CharacterBody3D

## Milestone 1: basic 3D space flight.
## The flight model is intentionally arcade-like, with acceleration and momentum.

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

	rotate_object_local(Vector3.RIGHT, mouse_pitch)
	rotate_y(mouse_yaw)

	var pitch := Input.get_axis("pitch_down", "pitch_up")
	var yaw := Input.get_axis("yaw_left", "yaw_right")
	var roll := Input.get_axis("roll_left", "roll_right")

	rotate_object_local(Vector3.RIGHT, pitch * keyboard_pitch_speed * delta)
	rotate_y(yaw * keyboard_yaw_speed * delta)
	rotate_object_local(Vector3.FORWARD, roll * roll_speed * delta)

func _apply_throttle(delta: float) -> void:
	var throttle_input := Input.get_axis("throttle_down", "throttle_up")
	throttle = clamp(throttle + throttle_input * delta, -1.0, 1.0)

	if Input.is_action_just_pressed("brake"):
		throttle = 0.0

	boost_active = Input.is_action_pressed("boost") and throttle > 0.0

func _apply_translation(delta: float) -> void:
	var target_speed := throttle * max_speed

	if boost_active:
		target_speed = boost_speed

	if throttle < 0.0:
		target_speed = throttle * reverse_speed

	var forward_velocity := -global_transform.basis.z * target_speed
	var current_forward := velocity.project(-global_transform.basis.z)

	var rate := acceleration
	if target_speed == 0.0:
		rate = brake_strength
	elif boost_active:
		rate = boost_acceleration

	velocity += (forward_velocity - current_forward).limit_length(rate * delta)

	var strafe_input := Input.get_axis("strafe_left", "strafe_right")
	var vertical_input := Input.get_axis("strafe_down", "strafe_up")

	var local_strafe := (
		global_transform.basis.x * strafe_input +
		global_transform.basis.y * vertical_input
	) * strafe_speed

	velocity += local_strafe * delta

func get_speed() -> float:
	return velocity.length()

func get_throttle_percent() -> float:
	return throttle
