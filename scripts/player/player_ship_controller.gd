class_name PlayerShipController
extends ShipController

## Player input controller.
##
## Converts mouse and keyboard input into flight intent.
## The Ship remains responsible for interpreting that intent and applying
## movement, acceleration, braking and rotation.

@export_category("Mouse")
@export var mouse_sensitivity: float = 0.02

var mouse_input := Vector2.ZERO

func _ready() -> void:
	super._ready()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input += event.relative

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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

	return intent

func _axis(negative_key: Key, positive_key: Key) -> float:
	return float(Input.is_key_pressed(positive_key)) - float(Input.is_key_pressed(negative_key))
