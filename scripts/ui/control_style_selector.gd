extends CanvasLayer

@onready var rotation_keys_button: Button = $Panel/Container/RotationKeysButton
@onready var mouse_aim_button: Button = $Panel/Container/MouseAimButton
@onready var player_ship: Node = get_tree().get_first_node_in_group("player_ship")

func _ready() -> void:
	rotation_keys_button.pressed.connect(_select_rotation_keys)
	mouse_aim_button.pressed.connect(_select_mouse_aim)
	_update_buttons()

func _select_rotation_keys() -> void:
	WorldState.control_style = 0
	_apply_to_player()
	_update_buttons()

func _select_mouse_aim() -> void:
	WorldState.control_style = 1
	_apply_to_player()
	_update_buttons()

func _apply_to_player() -> void:
	player_ship = get_tree().get_first_node_in_group("player_ship") as Node
	if not is_instance_valid(player_ship):
		return

	player_ship.call("set_control_style", WorldState.control_style)

func _update_buttons() -> void:
	rotation_keys_button.button_pressed = WorldState.control_style == 0
	mouse_aim_button.button_pressed = WorldState.control_style == 1
