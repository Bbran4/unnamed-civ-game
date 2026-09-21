extends Area2D

@export_enum("Evidence", "Witness", "Suspect") var interaction_type: String = "Evidence"
@export var evidence_id: String = ""
@export var evidence_description: String = "Unknown clue"
@export var interaction_range: float = 70.0

var station_player: CharacterBody2D
var player_in_range: bool = false

@onready var prompt: Label = $Prompt

func _ready() -> void:
	station_player = get_tree().get_first_node_in_group("station_player") as CharacterBody2D
	prompt.visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(station_player):
		station_player = get_tree().get_first_node_in_group("station_player") as CharacterBody2D
		return

	var distance_to_player: float = global_position.distance_to(station_player.global_position)
	var was_in_range: bool = player_in_range
	player_in_range = distance_to_player <= interaction_range

	if player_in_range != was_in_range:
		prompt.visible = player_in_range

	if player_in_range and Input.is_action_just_pressed("interact"):
		_interact()

func _interact() -> void:
	var investigation: Node = get_parent()
	if not investigation.has_method("register_evidence"):
		return

	match interaction_type:
		"Evidence":
			investigation.register_evidence(evidence_id, evidence_description)
		"Witness":
			investigation.register_witness()
		"Suspect":
			investigation.register_suspect()
