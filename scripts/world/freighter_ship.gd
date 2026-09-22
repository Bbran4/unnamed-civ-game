class_name FreighterShip
extends CivilianShip

@export var ship_data: ShipData

var cargo_manifest: Dictionary = {}
var cargo_units: int = 0
var cargo_good_id: String = ""
var cargo_resource_id: String = ""
var cargo_is_resource: bool = false

func setup(start_station_id: String) -> void:
	super.setup(start_station_id)
	cargo_manifest.clear()
	cargo_units = 0
	cargo_good_id = ""
	cargo_resource_id = ""
	cargo_is_resource = false

func _select_destination() -> void:
	if space_system == null:
		return

	var origin_station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if origin_station == null or origin_station.market == null:
		super._select_destination()
		return

	var best_destination: GeneratedStationData = null
	var best_profit: float = 0.0
	var best_is_resource: bool = false
	var best_item_id: String = ""

	for station: GeneratedStationData in space_system.generated_system.stations:
		if station == null or station.id == origin_station_id:
			continue
		if station.market == null or station.station_type == null:
			continue

		for resource_data: ResourceData in origin_station.station_type.resource_exports:
			if resource_data == null:
				continue
			if not _station_imports_resource(station, resource_data.id):
				continue

			var available_supply: float = float(origin_station.market.supply.get(resource_data.id, 0.0))
			if available_supply <= 0.0:
				continue

			var origin_price: float = float(origin_station.market.current_prices.get(resource_data.id, resource_data.base_value))
			var destination_price: float = float(station.market.current_prices.get(resource_data.id, resource_data.base_value))
			var profit: float = destination_price - origin_price

			if profit > best_profit:
				best_profit = profit
				best_destination = station
				best_is_resource = true
				best_item_id = resource_data.id

		for good_data: GoodData in origin_station.station_type.good_exports:
			if good_data == null:
				continue
			if not _station_imports_good(station, good_data.id):
				continue

			var available_supply: float = float(origin_station.market.supply.get(good_data.id, 0.0))
			if available_supply <= 0.0:
				continue

			var origin_price: float = float(origin_station.market.current_prices.get(good_data.id, good_data.base_value))
			var destination_price: float = float(station.market.current_prices.get(good_data.id, good_data.base_value))
			var profit: float = destination_price - origin_price

			if profit > best_profit:
				best_profit = profit
				best_destination = station
				best_is_resource = false
				best_item_id = good_data.id

	if best_destination == null:
		super._select_destination()
		return

	destination_station_id = best_destination.id
	journey_type = JourneyType.TRADE_RUN
	journey_time = 0.0
	travel_state = TravelState.TRAVEL
	velocity = Vector2.ZERO

	_load_cargo_from_origin(best_is_resource, best_item_id)

func _load_cargo_from_origin(is_resource: bool, item_id: String) -> void:
	cargo_manifest.clear()
	cargo_units = 0
	cargo_good_id = ""
	cargo_resource_id = ""
	cargo_is_resource = is_resource

	if ship_data == null or item_id.is_empty():
		return

	var cargo_capacity: int = ship_data.get_total_cargo_capacity()
	if cargo_capacity <= 0:
		return

	var origin_station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if origin_station == null or origin_station.market == null:
		return

	var available_supply: float = float(origin_station.market.supply.get(item_id, 0.0))
	var units: int = mini(cargo_capacity, maxi(1, int(floor(available_supply))))
	if units <= 0:
		return

	cargo_manifest[item_id] = units
	cargo_units = units

	if is_resource:
		cargo_resource_id = item_id
	else:
		cargo_good_id = item_id

	origin_station.market.supply[item_id] = maxf(
		0.0,
		available_supply - float(units)
	)

	_update_market_price_for_item(origin_station.market, item_id, is_resource)

func _remain_docked(delta: float) -> void:
	var was_docked: bool = travel_state == TravelState.DOCKED
	super._remain_docked(delta)

	if was_docked and travel_state == TravelState.SELECT_DESTINATION and cargo_units > 0:
		_unload_cargo()
		cargo_manifest.clear()
		cargo_units = 0
		cargo_good_id = ""
		cargo_resource_id = ""
		cargo_is_resource = false

func _unload_cargo() -> void:
	var destination_station: GeneratedStationData = _get_station_by_id(destination_station_id)
	if destination_station == null or destination_station.market == null:
		return

	var item_id: String = cargo_resource_id if cargo_is_resource else cargo_good_id
	if item_id.is_empty():
		return

	var current_supply: float = float(destination_station.market.supply.get(item_id, 0.0))
	destination_station.market.supply[item_id] = current_supply + float(cargo_units)
	_update_market_price_for_item(destination_station.market, item_id, cargo_is_resource)

func _update_market_price_for_item(
	market_data: MarketData,
	item_id: String,
	is_resource: bool
) -> void:
	var base_value: float = _get_item_base_value(item_id, is_resource)
	if base_value <= 0.0:
		return

	var supply: float = float(market_data.supply.get(item_id, 0.0))
	var demand: float = float(market_data.demand.get(item_id, 0.0))
	market_data.current_prices[item_id] = Market.new().calculate_price(
		base_value,
		supply,
		demand
	)

func _get_item_base_value(item_id: String, is_resource: bool) -> float:
	if is_resource:
		for resource_data: ResourceData in _get_current_station_resource_exports():
			if resource_data != null and resource_data.id == item_id:
				return resource_data.base_value
		for resource_data: ResourceData in _get_current_station_resource_imports():
			if resource_data != null and resource_data.id == item_id:
				return resource_data.base_value
	else:
		for good_data: GoodData in _get_current_station_good_exports():
			if good_data != null and good_data.id == item_id:
				return good_data.base_value
		for good_data: GoodData in _get_current_station_good_imports():
			if good_data != null and good_data.id == item_id:
				return good_data.base_value

	return 0.0

func _get_current_station_resource_exports() -> Array[ResourceData]:
	var station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if station == null or station.station_type == null:
		return []
	return station.station_type.resource_exports

func _get_current_station_resource_imports() -> Array[ResourceData]:
	var station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if station == null or station.station_type == null:
		return []
	return station.station_type.resource_imports

func _get_current_station_good_exports() -> Array[GoodData]:
	var station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if station == null or station.station_type == null:
		return []
	return station.station_type.good_exports

func _get_current_station_good_imports() -> Array[GoodData]:
	var station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if station == null or station.station_type == null:
		return []
	return station.station_type.good_imports

func _station_imports_resource(station: GeneratedStationData, resource_id: String) -> bool:
	if station.station_type == null:
		return false

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data != null and resource_data.id == resource_id:
			return true

	return false

func _station_imports_good(station: GeneratedStationData, good_id: String) -> bool:
	if station.station_type == null:
		return false

	for good_data: GoodData in station.station_type.good_imports:
		if good_data != null and good_data.id == good_id:
			return true

	return false

func _get_station_by_id(station_id: String) -> GeneratedStationData:
	if space_system == null:
		return null

	for station: GeneratedStationData in space_system.generated_system.stations:
		if station.id == station_id:
			return station

	return null
