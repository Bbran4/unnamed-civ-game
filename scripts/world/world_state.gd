extends Node

const SAVE_VERSION := 3

var world_seed: int = 0
var current_era: int = 0
var world_time: float = 0.0
var player_civilization_id: String = ""
var civilizations: Dictionary = {}
var world_data: Dictionary = {}
var legacy_data: Dictionary = {}

func new_world(seed_value: int) -> void:
	world_seed = seed_value
	current_era = 0
	world_time = 0.0
	player_civilization_id = ""
	civilizations.clear()

	var generator := WorldGenerator.new()
	world_data = generator.generate(seed_value)

	legacy_data = {
		"research_points": 0,
		"technologies": [],
		"bonuses": {},
		"monuments": []
	}

func tick(delta: float) -> void:
	world_time += delta

func add_civilization(civilization: Dictionary) -> void:
	var id: String = str(civilization.get("id", ""))
	if id.is_empty():
		push_error("Cannot add civilization without an id.")
		return
	civilizations[id] = civilization

func get_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"world_seed": world_seed,
		"current_era": current_era,
		"world_time": world_time,
		"player_civilization_id": player_civilization_id,
		"civilizations": civilizations,
		"world_data": world_data,
		"legacy_data": legacy_data
	}

func load_save_data(data: Dictionary) -> void:
	world_seed = int(data.get("world_seed", 0))
	current_era = int(data.get("current_era", 0))
	world_time = float(data.get("world_time", 0.0))
	player_civilization_id = str(data.get("player_civilization_id", ""))
	civilizations = data.get("civilizations", {})
	world_data = data.get("world_data", {})
	legacy_data = data.get("legacy_data", {})

	if not _has_generated_map():
		var generator := WorldGenerator.new()
		world_data = generator.generate(world_seed)

func _has_generated_map() -> bool:
	var width := int(world_data.get("width", 0))
	var height := int(world_data.get("height", 0))
	var terrain: Array = world_data.get("terrain", [])
	var resources: Array = world_data.get("resources", [])
	return (
		width > 0
		and height > 0
		and terrain.size() == width * height
		and resources.size() == width * height
	)
