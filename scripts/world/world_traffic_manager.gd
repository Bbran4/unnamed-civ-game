class_name WorldTrafficManager
extends Node2D

const CIVILIAN_SCENE: PackedScene = preload("res://scenes/world/civilian_ship.tscn")
const FREIGHTER_SCENE: PackedScene = preload("res://scenes/world/freighter_ship.tscn")

@export var civilian_ship_count: int = 28
@export var freighter_ship_count: int = 7

var space_system: SpaceSystem
var civilian_ships: Array[CivilianShip] = []

func _ready() -> void:
	space_system = get_tree().get_first_node_in_group("space_system") as SpaceSystem
	if space_system == null:
		return

	call_deferred("_spawn_initial_traffic")

func _process(_delta: float) -> void:
	_remove_invalid_ships()
	if space_system == null:
		return

	while _count_civilian_ships() < civilian_ship_count:
		_spawn_civilian()

	while _count_freighter_ships() < freighter_ship_count:
		_spawn_freighter()

func _spawn_initial_traffic() -> void:
	for _index: int in range(civilian_ship_count):
		_spawn_civilian()

	for _index: int in range(freighter_ship_count):
		_spawn_freighter()

func _spawn_civilian() -> void:
	if space_system == null:
		return

	var stations: Array[GeneratedStationData] = space_system.generated_system.stations
	if stations.is_empty():
		return

	var station_index: int = randi_range(0, stations.size() - 1)
	var station: GeneratedStationData = stations[station_index]
	var civilian_ship: CivilianShip = CIVILIAN_SCENE.instantiate() as CivilianShip
	if civilian_ship == null:
		return

	add_child(civilian_ship)
	civilian_ship.global_position = space_system.get_station_position(station.id)
	civilian_ship.setup(station.id)
	civilian_ships.append(civilian_ship)

func _remove_invalid_ships() -> void:
	var valid_ships: Array[CivilianShip] = []

	for civilian_ship: CivilianShip in civilian_ships:
		if is_instance_valid(civilian_ship):
			valid_ships.append(civilian_ship)

	civilian_ships = valid_ships

func _spawn_freighter() -> void:
	if space_system == null:
		return

	var stations: Array[GeneratedStationData] = space_system.generated_system.stations
	if stations.is_empty():
		return

	var station_index: int = randi_range(0, stations.size() - 1)
	var station: GeneratedStationData = stations[station_index]
	var freighter_ship: FreighterShip = FREIGHTER_SCENE.instantiate() as FreighterShip
	if freighter_ship == null:
		return

	add_child(freighter_ship)
	freighter_ship.global_position = space_system.get_station_position(station.id)
	freighter_ship.setup(station.id)
	civilian_ships.append(freighter_ship)

func _count_civilian_ships() -> int:
	var count: int = 0
	for ship: CivilianShip in civilian_ships:
		if is_instance_valid(ship) and ship is not FreighterShip:
			count += 1
	return count

func _count_freighter_ships() -> int:
	var count: int = 0
	for ship: CivilianShip in civilian_ships:
		if is_instance_valid(ship) and ship is FreighterShip:
			count += 1
	return count
