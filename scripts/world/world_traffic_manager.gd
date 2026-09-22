class_name WorldTrafficManager
extends Node2D

const CIVILIAN_SCENE: PackedScene = preload("res://scenes/world/civilian_ship.tscn")
const FREIGHTER_SCENE: PackedScene = preload("res://scenes/world/freighter_ship.tscn")

var space_system: SpaceSystem
var visual_ships: Dictionary = {}

func _ready() -> void:
	space_system = get_tree().get_first_node_in_group("space_system") as SpaceSystem
	call_deferred("_refresh_visuals")

func _process(_delta: float) -> void:
	if space_system == null:
		space_system = get_tree().get_first_node_in_group("space_system") as SpaceSystem
		if space_system == null:
			return
	_refresh_visuals()

func _refresh_visuals() -> void:
	var active_records: Array[Dictionary] = GalaxySimulation.get_traffic_for_system(space_system.system_id)
	var active_ids: Dictionary = {}

	for record: Dictionary in active_records:
		var traffic_id: String = String(record.get("id", ""))
		if traffic_id.is_empty():
			continue
		active_ids[traffic_id] = true

		var ship: CivilianShip = visual_ships.get(traffic_id) as CivilianShip
		if ship == null or not is_instance_valid(ship):
			ship = _create_visual_ship(record)
			if ship == null:
				continue
			visual_ships[traffic_id] = ship

		_apply_record_to_visual(ship, record)

	for traffic_id: String in visual_ships.keys():
		if active_ids.has(traffic_id):
			continue
		var ship_to_remove: CivilianShip = visual_ships[traffic_id] as CivilianShip
		if is_instance_valid(ship_to_remove):
			ship_to_remove.queue_free()
		visual_ships.erase(traffic_id)

func _create_visual_ship(record: Dictionary) -> CivilianShip:
	var scene: PackedScene = FREIGHTER_SCENE if bool(record.get("is_freighter", false)) else CIVILIAN_SCENE
	var ship: CivilianShip = scene.instantiate() as CivilianShip
	if ship == null:
		return null
	add_child(ship)
	ship.simulation_visual_only = true
	return ship

func _apply_record_to_visual(ship: CivilianShip, record: Dictionary) -> void:
	ship.simulation_visual_only = true

	var state: String = String(record.get("state", "docked"))
	var system_id: String = String(record.get("system_id", ""))
	var origin_station_id: String = String(record.get("origin_station_id", ""))
	var destination_station_id: String = String(record.get("destination_station_id", ""))
	var progress: float = float(record.get("progress", 0.0))

	if state == "inter_system_travel":
		ship.visible = false
		return

	ship.visible = true

	if state == "docked" or destination_station_id.is_empty():
		ship.global_position = GalaxyState.get_station_position(system_id, origin_station_id)
		return

	var origin_position: Vector2 = GalaxyState.get_station_position(system_id, origin_station_id)
	var destination_position: Vector2 = GalaxyState.get_station_position(system_id, destination_station_id)
	ship.global_position = origin_position.lerp(destination_position, progress)

	if destination_position != origin_position:
		ship.rotation = origin_position.direction_to(destination_position).angle()
