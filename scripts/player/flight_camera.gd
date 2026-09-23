extends Camera3D

@export var target_path: NodePath
@export var follow_distance: float = 10.0
@export var follow_height: float = 3.0
@export var position_smoothing: float = 7.0
@export var rotation_smoothing: float = 8.0

var target: Node3D

func _ready() -> void:
	target = get_node_or_null(target_path)

func _process(delta: float) -> void:
	if target == null:
		return

	var target_basis := target.global_transform.basis.orthonormalized()
	var desired_position := target.global_position + target_basis.z * follow_distance
	desired_position += target_basis.y * follow_height

	global_position = global_position.lerp(desired_position, 1.0 - exp(-position_smoothing * delta))

	var current_rotation := global_basis.orthonormalized().get_rotation_quaternion()
	var target_rotation := target_basis.get_rotation_quaternion()
	var rotation_weight := 1.0 - exp(-rotation_smoothing * delta)
	global_basis = current_rotation.slerp(target_rotation, rotation_weight).get_basis()
