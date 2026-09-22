class_name FreighterShip
extends CivilianShip

@export var ship_data: ShipData
@export var cargo_capacity: int = 250

var cargo_manifest: Dictionary = {}
var cargo_units: int = 0

func setup(start_station_id: String) -> void:
	super.setup(start_station_id)
	cargo_manifest.clear()
	cargo_units = 0

func _select_destination() -> void:
	if space_system == null:
		return

	var origin_station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if origin_station == null or origin_station.market == null or origin_station.station_type == null:
		_enter_docked_state()
		return

	var best_destination: GeneratedStationData = null
	var best_manifest: Dictionary = {}
	var best_profit: float = 0.0

	for station: GeneratedStationData in space_system.generated_system.stations:
		if station == null or station.id == origin_station_id:
			continue
		if station.market == null or station.station_type == null:
			continue

		var candidate_manifest: Dictionary = _build_trade_manifest(origin_station, station)
		if candidate_manifest.is_empty():
			continue

		var candidate_profit: float = _calculate_manifest_profit(origin_station, station, candidate_manifest)
		if candidate_profit > best_profit:
			best_profit = candidate_profit
			best_destination = station
			best_manifest = candidate_manifest

	if best_destination == null or best_manifest.is_empty():
		_enter_docked_state()
		return

	if not _load_cargo_from_manifest(origin_station, best_manifest):
		_enter_docked_state()
		return

	destination_station_id = best_destination.id
	journey_type = JourneyType.TRADE_RUN
	journey_time = 0.0
	travel_state = TravelState.TRAVEL
	velocity = Vector2.ZERO

func _build_trade_manifest(
	origin_station: GeneratedStationData,
	destination_station: GeneratedStationData
) -> Dictionary:
	var manifest: Dictionary = {}
	var selected_items: Dictionary = {}
	var remaining_capacity: int = maxi(cargo_capacity, 0)

	while remaining_capacity > 0:
		var best_item_id: String = ""
		var best_item_is_resource: bool = false
		var best_profit_per_unit: float = 0.0
		var best_available_units: int = 0

		for resource_data: ResourceData in origin_station.station_type.resource_exports:
			if resource_data == null:
				continue
			if selected_items.has(resource_data.id):
				continue
			if not _station_imports_resource(destination_station, resource_data.id):
				continue

			var available_supply: float = float(origin_station.market.supply.get(resource_data.id, 0.0))
			if available_supply < 1.0:
				continue

			var origin_price: float = float(
				origin_station.market.current_prices.get(
					resource_data.id,
					resource_data.base_value
				)
			)
			var destination_price: float = float(
				destination_station.market.current_prices.get(
					resource_data.id,
					resource_data.base_value
				)
			)
			var profit_per_unit: float = destination_price - origin_price
			var available_units: int = mini(
				remaining_capacity,
				int(floor(available_supply))
			)

			if profit_per_unit > best_profit_per_unit and available_units > 0:
				best_item_id = resource_data.id
				best_item_is_resource = true
				best_profit_per_unit = profit_per_unit
				best_available_units = available_units

		for good_data: GoodData in origin_station.station_type.good_exports:
			if good_data == null:
				continue
			if selected_items.has(good_data.id):
				continue
			if not _station_imports_good(destination_station, good_data.id):
				continue

			var available_supply: float = float(origin_station.market.supply.get(good_data.id, 0.0))
			if available_supply < 1.0:
				continue

			var origin_price: float = float(
				origin_station.market.current_prices.get(
					good_data.id,
					good_data.base_value
				)
			)
			var destination_price: float = float(
				destination_station.market.current_prices.get(
					good_data.id,
					good_data.base_value
				)
			)
			var profit_per_unit: float = destination_price - origin_price
			var available_units: int = mini(
				remaining_capacity,
				int(floor(available_supply))
			)

			if profit_per_unit > best_profit_per_unit and available_units > 0:
				best_item_id = good_data.id
				best_item_is_resource = false
				best_profit_per_unit = profit_per_unit
				best_available_units = available_units

		if best_item_id.is_empty() or best_profit_per_unit <= 0.0 or best_available_units <= 0:
			break

		manifest[best_item_id] = {
			"units": best_available_units,
			"is_resource": best_item_is_resource
		}
		selected_items[best_item_id] = true
		remaining_capacity -= best_available_units

	return manifest

func _calculate_manifest_profit(
	origin_station: GeneratedStationData,
	destination_station: GeneratedStationData,
	manifest: Dictionary
) -> float:
	var total_profit: float = 0.0

	for item_id: String in manifest.keys():
		var cargo_entry: Dictionary = manifest[item_id]
		var units: int = int(cargo_entry.get("units", 0))
		var is_resource: bool = bool(cargo_entry.get("is_resource", false))
		if units <= 0:
			continue

		var base_value: float = _get_item_base_value(origin_station, item_id, is_resource)
		var origin_price: float = float(
			origin_station.market.current_prices.get(item_id, base_value)
		)
		var destination_price: float = float(
			destination_station.market.current_prices.get(item_id, base_value)
		)
		total_profit += float(units) * (destination_price - origin_price)

	return total_profit

func _load_cargo_from_manifest(
	origin_station: GeneratedStationData,
	manifest: Dictionary
) -> bool:
	cargo_manifest.clear()
	cargo_units = 0

	if cargo_capacity <= 0 or manifest.is_empty():
		return false

	for item_id: String in manifest.keys():
		var cargo_entry: Dictionary = manifest[item_id]
		var requested_units: int = int(cargo_entry.get("units", 0))
		var is_resource: bool = bool(cargo_entry.get("is_resource", false))
		if requested_units <= 0:
			continue

		var available_supply: float = float(origin_station.market.supply.get(item_id, 0.0))
		var units: int = mini(
			requested_units,
			mini(
				int(floor(available_supply)),
				cargo_capacity - cargo_units
			)
		)
		if units <= 0:
			continue

		cargo_manifest[item_id] = {
			"units": units,
			"is_resource": is_resource
		}
		cargo_units += units

		origin_station.market.supply[item_id] = maxf(
			0.0,
			available_supply - float(units)
		)
		_update_market_price_for_item(
			origin_station.market,
			item_id,
			is_resource,
			origin_station
		)

	return cargo_units > 0

func _remain_docked(delta: float) -> void:
	var was_docked: bool = travel_state == TravelState.DOCKED
	super._remain_docked(delta)

	if was_docked and travel_state == TravelState.SELECT_DESTINATION:
		_unload_cargo()

		cargo_manifest.clear()
		cargo_units = 0

func _unload_cargo() -> void:
	if cargo_manifest.is_empty():
		return

	var destination_station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if destination_station == null or destination_station.market == null:
		return

	for item_id: String in cargo_manifest.keys():
		var cargo_entry: Dictionary = cargo_manifest[item_id]
		var units: int = int(cargo_entry.get("units", 0))
		var is_resource: bool = bool(cargo_entry.get("is_resource", false))
		if units <= 0:
			continue

		var current_supply: float = float(destination_station.market.supply.get(item_id, 0.0))
		destination_station.market.supply[item_id] = current_supply + float(units)
		_update_market_price_for_item(
			destination_station.market,
			item_id,
			is_resource,
			destination_station
		)

func _update_market_price_for_item(
	market_data: MarketData,
	item_id: String,
	is_resource: bool,
	station: GeneratedStationData
) -> void:
	var base_value: float = _get_item_base_value(station, item_id, is_resource)
	if base_value <= 0.0:
		return

	var supply: float = float(market_data.supply.get(item_id, 0.0))
	var demand: float = float(market_data.demand.get(item_id, 0.0))
	market_data.current_prices[item_id] = Market.new().calculate_price(
		base_value,
		supply,
		demand
	)

func _get_item_base_value(
	station: GeneratedStationData,
	item_id: String,
	is_resource: bool
) -> float:
	if station == null or station.station_type == null:
		return 0.0

	if is_resource:
		for resource_data: ResourceData in station.station_type.resource_exports:
			if resource_data != null and resource_data.id == item_id:
				return resource_data.base_value
		for resource_data: ResourceData in station.station_type.resource_imports:
			if resource_data != null and resource_data.id == item_id:
				return resource_data.base_value
	else:
		for good_data: GoodData in station.station_type.good_exports:
			if good_data != null and good_data.id == item_id:
				return good_data.base_value
		for good_data: GoodData in station.station_type.good_imports:
			if good_data != null and good_data.id == item_id:
				return good_data.base_value

	return 0.0

func _station_imports_resource(
	station: GeneratedStationData,
	resource_id: String
) -> bool:
	if station.station_type == null:
		return false

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data != null and resource_data.id == resource_id:
			return true

	return false

func _station_imports_good(
	station: GeneratedStationData,
	good_id: String
) -> bool:
	if station.station_type == null:
		return false

	for good_data: GoodData in station.station_type.good_imports:
		if good_data != null and good_data.id == good_id:
			return true

	return false

func _enter_docked_state() -> void:
	travel_state = TravelState.DOCKED
	dock_time_remaining = dock_duration
	velocity = Vector2.ZERO

func _get_station_by_id(station_id: String) -> GeneratedStationData:
	if space_system == null:
		return null

	for station: GeneratedStationData in space_system.generated_system.stations:
		if station.id == station_id:
			return station

	return null
