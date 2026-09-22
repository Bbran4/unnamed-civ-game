class_name WorldTrafficManager
extends Node2D

const CIVILIAN_SCENE: PackedScene = preload("res://scenes/world/civilian_ship.tscn")

@export var civilian_ship_count: int = 6

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

    while civilian_ships.size() < civilian_ship_count:
        _spawn_civilian()

func _spawn_initial_traffic() -> void:
    for _index: int in range(civilian_ship_count):
        _spawn_civilian()

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
