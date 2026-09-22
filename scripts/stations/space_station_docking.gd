extends Node2D

@export var docking_range: float = 180.0
@export_file("*.tscn") var destination_scene: String = "res://scenes/stations/first_station_interior.tscn"

var player_ship: CharacterBody2D
var player_in_range: bool = false

@onready var docking_prompt: Label = $DockingPrompt

func _ready() -> void:
    player_ship = get_tree().get_first_node_in_group("player_ship") as CharacterBody2D
    docking_prompt.visible = false

func _process(_delta: float) -> void:
    if not is_instance_valid(player_ship):
        player_ship = get_tree().get_first_node_in_group("player_ship") as CharacterBody2D
        return

    var distance_to_player: float = global_position.distance_to(player_ship.global_position)
    var was_in_range: bool = player_in_range
    player_in_range = distance_to_player <= docking_range

    if player_in_range != was_in_range:
        docking_prompt.visible = player_in_range

    if player_in_range and Input.is_action_just_pressed("interact"):
        _dock_player()

func _dock_player() -> void:
    if destination_scene.is_empty():
        push_error("Docking destination scene is not configured.")
        return

    WorldState.station_exit_position = global_position + Vector2(250.0, 0.0)
    WorldState.current_station_id = name
    WorldState.returning_from_station = false
    SceneManager.change_scene(destination_scene)
