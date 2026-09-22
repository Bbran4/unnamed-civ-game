class_name FreighterShip
extends CivilianShip

@export var ship_data: ShipData

var cargo_manifest: Dictionary = {}
var cargo_units: int = 0
var cargo_good_id: String = ""

func setup(start_station_id: String) -> void:
    super.setup(start_station_id)
    cargo_manifest.clear()
    cargo_units = 0
    cargo_good_id = ""

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
    var destination_station: GeneratedStationData = _get_station_by_id(destination_station_id)
    if origin_station == null or origin_station.station_type == null or destination_station == null or destination_station.station_type == null:
        return

    var export_candidates: Array[GoodData] = []
    for good: GoodData in origin_station.station_type.good_exports:
        if good == null:
            continue
        if _station_imports_good(destination_station, good.id):
            export_candidates.append(good)

    if export_candidates.is_empty():
        return

    var remaining_capacity: int = cargo_capacity
    var cargo_index: int = randi_range(0, export_candidates.size() - 1)
    var selected_good: GoodData = export_candidates[cargo_index]
    var units: int = mini(remaining_capacity, maxi(1, int(float(cargo_capacity) * randf_range(0.25, 0.75))))

    cargo_manifest[selected_good.id] = units
    cargo_units = units
    cargo_good_id = selected_good.id

    if origin_station.market != null:
        var origin_supply: float = float(origin_station.market.supply.get(cargo_good_id, 0.0))
        origin_station.market.supply[cargo_good_id] = maxf(0.0, origin_supply - float(units))
        _update_market_price(origin_station.market, selected_good)

func _remain_docked(delta: float) -> void:
    var was_docked: bool = travel_state == TravelState.DOCKED
    super._remain_docked(delta)

    if was_docked and travel_state == TravelState.SELECT_DESTINATION and cargo_units > 0:
        _unload_cargo()
        cargo_manifest.clear()
        cargo_units = 0
        cargo_good_id = ""

func _unload_cargo() -> void:
    var destination_station: GeneratedStationData = _get_station_by_id(origin_station_id)
    if destination_station == null or destination_station.market == null:
        return
    if cargo_good_id.is_empty():
        return

    var current_supply: float = float(destination_station.market.supply.get(cargo_good_id, 0.0))
    destination_station.market.supply[cargo_good_id] = current_supply + float(cargo_units)

    var good: GoodData = _get_good_from_station(destination_station, cargo_good_id)
    if good != null:
        _update_market_price(destination_station.market, good)

func _get_good_from_station(station: GeneratedStationData, good_id: String) -> GoodData:
    if station.station_type == null:
        return null

    for good: GoodData in station.station_type.good_imports:
        if good != null and good.id == good_id:
            return good

    for good: GoodData in station.station_type.good_exports:
        if good != null and good.id == good_id:
            return good

    return null

func _update_market_price(market: MarketData, good: GoodData) -> void:
    var supply: float = float(market.supply.get(good.id, 0.0))
    var demand: float = float(market.demand.get(good.id, 0.0))
    market.current_prices[good.id] = Market.new().calculate_price(good.base_value, supply, demand)

func _station_imports_good(station: GeneratedStationData, good_id: String) -> bool:
    if station.station_type == null:
        return false

    for good: GoodData in station.station_type.good_imports:
        if good != null and good.id == good_id:
            return true

    return false
