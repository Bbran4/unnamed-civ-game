extends Camera3D

@export var target_path: NodePath
@export var follow_distance: float = 10.0
@export var follow_height: float = 3.0
@export var position_smoothing: float = 7.0
@export var rotation_smoothing: float = 8.0
@export var normal_fov: float = 70.0
@export var boost_fov: float = 82.0
@export var fov_smoothing: float = 5.0

var target: Node3D

func _ready() -> void:
	target = get_node_or_null(target_path)
	fov = normal_fov

func _process(delta: float) -> void:
	if target == null:
		return

	var target_basis := target.global_transform.basis.orthonormalized()
	var desired_position := target.global_position + target_basis.z * follow_distance
	desired_position += target_basis.y * follow_height

	var position_weight := 1.0 - exp(-position_smoothing * delta)
	global_position = global_position.lerp(desired_position, position_weight)

	var current_rotation := global_basis.orthonormalized().get_rotation_quaternion()
	var target_rotation := target_basis.get_rotation_quaternion()
	var rotation_weight := 1.0 - exp(-rotation_smoothing * delta)
	global_transform.basis = Basis(current_rotation.slerp(target_rotation, rotation_weight))

	var desired_fov := boost_fov if target.boost_active else normal_fov
	fov = lerp(fov, desired_fov, 1.0 - exp(-fov_smoothing * delta))
