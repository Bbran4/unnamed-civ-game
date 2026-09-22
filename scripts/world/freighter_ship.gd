class_name FreighterShip
extends CivilianShip

@export var ship_data: ShipData

var cargo_manifest: Dictionary = {}
var cargo_units: int = 0

func setup(start_station_id: String) -> void:
    super.setup(start_station_id)
    cargo_manifest.clear()
    cargo_units = 0

func _select_destination() -> void:
    super._select_destination()
    if destination_station_id.is_empty():
        return

    _load_cargo_from_origin()

func _load_cargo_from_origin() -> void:
    cargo_manifest.clear()
    cargo_units = 0

    if ship_data == null:
        return

    var cargo_capacity: int = ship_data.get_total_cargo_capacity()
    if cargo_capacity <= 0:
        return

    var origin_station: GeneratedStationData = _get_station_by_id(origin_station_id)
    if origin_station == null or origin_station.station_type == null:
        return

    var export_candidates: Array[GoodData] = []
    for good: GoodData in origin_station.station_type.good_exports:
        if good != null:
            export_candidates.append(good)

    if export_candidates.is_empty():
        return

    var remaining_capacity: int = cargo_capacity
    var cargo_index: int = randi_range(0, export_candidates.size() - 1)
    var selected_good: GoodData = export_candidates[cargo_index]
    var units: int = mini(remaining_capacity, maxi(1, int(float(cargo_capacity) * randf_range(0.25, 0.75))))

    cargo_manifest[selected_good.id] = units
    cargo_units = units

func _remain_docked(delta: float) -> void:
    super._remain_docked(delta)

    if travel_state == TravelState.SELECT_DESTINATION and cargo_units > 0:
        cargo_manifest.clear()
        cargo_units = 0
