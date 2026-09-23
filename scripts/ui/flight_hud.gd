extends CanvasLayer

@export var ship_path: NodePath
var ship: Node3D

@onready var speed_label: Label = $MarginContainer/VBoxContainer/Speed
@onready var throttle_label: Label = $MarginContainer/VBoxContainer/Throttle
@onready var status_label: Label = $MarginContainer/VBoxContainer/Status
@onready var help_label: Label = $MarginContainer/VBoxContainer/Help

func _ready() -> void:
	ship = get_node_or_null(ship_path)
	help_label.text = "W/S Throttle  |  Mouse Pitch/Yaw  |  Q/E Roll  |  A/D Strafe  |  Shift Boost  |  Space Brake  |  LMB Fire  |  Esc Release Mouse"

func _process(_delta: float) -> void:
	if ship == null:
		return
	speed_label.text = "SPEED  %03d m/s" % int(ship.get_speed())
	throttle_label.text = "THROTTLE  %03d%%" % int(ship.get_throttle_percent() * 100.0)
	status_label.text = "BOOST  ACTIVE" if ship.boost_active else "FLIGHT  CRUISE"
