extends Area2D

@export_file("*.tscn") var destination_scene: String = "res://scenes/main/game.tscn"
@export var interaction_range: float = 70.0

var station_player: CharacterBody2D
var player_in_range: bool = false

@onready var exit_prompt: Label = $ExitPrompt

func _ready() -> void:
	station_player = get_tree().get_first_node_in_group("station_player") as CharacterBody2D
	exit_prompt.visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(station_player):
		station_player = get_tree().get_first_node_in_group("station_player") as CharacterBody2D
		return

	var distance_to_player: float = global_position.distance_to(station_player.global_position)
	var was_in_range: bool = player_in_range
	player_in_range = distance_to_player <= interaction_range

	if player_in_range != was_in_range:
		exit_prompt.visible = player_in_range

	if player_in_range and Input.is_action_just_pressed("interact"):
		_leave_station()

func _leave_station() -> void:
	if destination_scene.is_empty():
		push_error("Station exit destination scene is not configured.")
		return

	SceneManager.change_scene(destination_scene)
