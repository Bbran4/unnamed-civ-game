class_name FreighterShip
extends CivilianShip

@export var ship_data: ShipData
@export var cargo_capacity: int = 250
@export var average_cargo_price: float = 50.0
@export var starting_credits: float = 25000.0
@export var fuel_capacity: float = 100.0
@export var starting_fuel: float = 100.0
@export var fuel_consumption_per_10000_distance: float = 5.0
@export var maximum_units_per_cargo_type: int = 100
@export var distance_price_scale: float = 40000.0

var credits: float = 0.0
var fuel_units: float = 0.0
var cargo_manifest: Dictionary = {}
var cargo_units: int = 0
var cargo_origin_station_id: String = ""
var cargo_route_distance: float = 0.0

func setup(start_station_id: String) -> void:
	super.setup(start_station_id)
	cargo_manifest.clear()
	cargo_units = 0
	cargo_origin_station_id = ""
	cargo_route_distance = 0.0

	credits = starting_credits
	if credits <= 0.0:
		credits = float(cargo_capacity) * average_cargo_price * 2.0

	fuel_units = clampf(starting_fuel, 0.0, fuel_capacity)

func _select_destination() -> void:
	if space_system == null:
		return

	var origin_station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if origin_station == null or origin_station.market == null or origin_station.station_type == null:
		_enter_docked_state()
		return

	var best_destination: GeneratedStationData = null
	var best_destination_system_id: String = ""
	var best_manifest: Dictionary = {}
	var best_profit: float = 0.0
	var best_route_distance: float = 0.0
	var best_is_inter_system: bool = false

	# Local, in-system destinations.
	for station: GeneratedStationData in space_system.generated_system.stations:
		if station == null or station.id == origin_station_id:
			continue
		if station.market == null or station.station_type == null:
			continue

		var route_distance: float = _get_station_distance(origin_station.id, station.id)
		var evaluation: Dictionary = _evaluate_trade_candidate(origin_station, station, route_distance, false)
		var candidate_profit: float = float(evaluation.get("profit", 0.0))

		if candidate_profit > best_profit:
			best_profit = candidate_profit
			best_destination = station
			best_destination_system_id = space_system.system_id
			best_manifest = evaluation.get("manifest", {})
			best_route_distance = route_distance
			best_is_inter_system = false

	# Distant, inter-system destinations. Every other generated star system is
	# considered as a possible trade partner, even while it is not loaded.
	for system_id: String in GalaxyState.get_all_system_ids():
		if system_id == space_system.system_id:
			continue

		var remote_system: GeneratedSystemData = GalaxyState.get_system(system_id)
		for station: GeneratedStationData in remote_system.stations:
			if station == null or station.market == null or station.station_type == null:
				continue

			var route_distance: float = GalaxyState.INTER_SYSTEM_DISTANCE
			var evaluation: Dictionary = _evaluate_trade_candidate(origin_station, station, route_distance, true)
			var candidate_profit: float = float(evaluation.get("profit", 0.0))

			if candidate_profit > best_profit:
				best_profit = candidate_profit
				best_destination = station
				best_destination_system_id = system_id
				best_manifest = evaluation.get("manifest", {})
				best_route_distance = route_distance
				best_is_inter_system = true

	if best_destination == null or best_manifest.is_empty() or best_profit <= 0.0:
		_enter_docked_state()
		return

	var fuel_required_for_best_route: float = (
		GalaxyState.INTER_SYSTEM_FUEL_COST if best_is_inter_system
		else _calculate_fuel_required(best_route_distance)
	)
	if not _refuel_for_trip(origin_station, fuel_required_for_best_route):
		_enter_docked_state()
		return

	fuel_units = maxf(0.0, fuel_units - fuel_required_for_best_route)

	if not _load_cargo_from_manifest(origin_station, best_manifest):
		_enter_docked_state()
		return

	if best_is_inter_system:
		# There is no rendered flight between star systems, so the freighter
		# jumps out immediately; the cargo arrives (and updates the
		# destination market) after GalaxyState.INTER_SYSTEM_TRANSIT_TIME.
		GalaxyState.queue_shipment(best_destination_system_id, best_destination.id, cargo_manifest)
		cargo_manifest.clear()
		cargo_units = 0
		queue_free()
		return

	destination_station_id = best_destination.id
	journey_type = JourneyType.TRADE_RUN
	journey_time = 0.0
	cargo_origin_station_id = origin_station.id
	cargo_route_distance = best_route_distance
	travel_state = TravelState.TRAVEL
	velocity = Vector2.ZERO

func _evaluate_trade_candidate(
	origin_station: GeneratedStationData,
	destination_station: GeneratedStationData,
	route_distance: float,
	is_inter_system: bool
) -> Dictionary:
	var candidate_manifest: Dictionary = _build_trade_manifest(origin_station, destination_station, route_distance)
	if candidate_manifest.is_empty():
		return {"profit": 0.0, "manifest": {}}

	var candidate_profit: float = _calculate_manifest_profit(
		origin_station,
		destination_station,
		candidate_manifest,
		route_distance
	)

	var fuel_required: float = (
		GalaxyState.INTER_SYSTEM_FUEL_COST if is_inter_system
		else _calculate_fuel_required(route_distance)
	)
	var fuel_cost: float = _calculate_fuel_cost(origin_station, fuel_required)
	candidate_profit -= fuel_cost

	return {"profit": candidate_profit, "manifest": candidate_manifest}

func _build_trade_manifest(
	origin_station: GeneratedStationData,
	destination_station: GeneratedStationData,
	route_distance: float
) -> Dictionary:
	var manifest: Dictionary = {}
	var selected_items: Dictionary = {}
	var remaining_capacity: int = maxi(cargo_capacity, 0)
	var remaining_credits: float = maxf(credits, 0.0)

	while remaining_capacity > 0 and remaining_credits > 0.0:
		var best_item_id: String = ""
		var best_item_is_resource: bool = false
		var best_profit_per_unit: float = 0.0
		var best_available_units: int = 0
		var best_origin_price: float = 0.0

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
				origin_station.market.current_prices.get(resource_data.id, resource_data.base_value)
			)
			var destination_price: float = _get_route_sale_price(
				destination_station,
				resource_data.id,
				resource_data.base_value,
				route_distance
			)
			var profit_per_unit: float = destination_price - origin_price
			var affordable_units: int = _get_affordable_units(origin_price, remaining_credits)
			var available_units: int = mini(
				remaining_capacity,
				mini(
					maximum_units_per_cargo_type,
					mini(int(floor(available_supply)), affordable_units)
				)
			)

			if profit_per_unit > best_profit_per_unit and available_units > 0:
				best_item_id = resource_data.id
				best_item_is_resource = true
				best_profit_per_unit = profit_per_unit
				best_available_units = available_units
				best_origin_price = origin_price

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
				origin_station.market.current_prices.get(good_data.id, good_data.base_value)
			)
			var destination_price: float = _get_route_sale_price(
				destination_station,
				good_data.id,
				good_data.base_value,
				route_distance
			)
			var profit_per_unit: float = destination_price - origin_price
			var affordable_units: int = _get_affordable_units(origin_price, remaining_credits)
			var available_units: int = mini(
				remaining_capacity,
				mini(
					maximum_units_per_cargo_type,
					mini(int(floor(available_supply)), affordable_units)
				)
			)

			if profit_per_unit > best_profit_per_unit and available_units > 0:
				best_item_id = good_data.id
				best_item_is_resource = false
				best_profit_per_unit = profit_per_unit
				best_available_units = available_units
				best_origin_price = origin_price

		if best_item_id.is_empty() or best_profit_per_unit <= 0.0 or best_available_units <= 0:
			break

		var best_base_value: float = _get_item_base_value(origin_station, best_item_id, best_item_is_resource)
		manifest[best_item_id] = {
			"units": best_available_units,
			"is_resource": best_item_is_resource,
			"purchase_price": best_origin_price,
			"base_value": best_base_value
		}
		selected_items[best_item_id] = true
		remaining_capacity -= best_available_units
		remaining_credits -= best_origin_price * float(best_available_units)

	return manifest

func _calculate_manifest_profit(
	origin_station: GeneratedStationData,
	destination_station: GeneratedStationData,
	manifest: Dictionary,
	route_distance: float
) -> float:
	var total_profit: float = 0.0

	for item_id: String in manifest.keys():
		var cargo_entry: Dictionary = manifest[item_id]
		var units: int = int(cargo_entry.get("units", 0))
		if units <= 0:
			continue

		var purchase_price: float = float(cargo_entry.get("purchase_price", 0.0))
		var base_value: float = _get_item_base_value(
			origin_station,
			item_id,
			bool(cargo_entry.get("is_resource", false))
		)
		var sale_price: float = _get_route_sale_price(
			destination_station,
			item_id,
			base_value,
			route_distance
		)
		total_profit += float(units) * (sale_price - purchase_price)

	return total_profit

func _load_cargo_from_manifest(
	origin_station: GeneratedStationData,
	manifest: Dictionary
) -> bool:
	cargo_manifest.clear()
	cargo_units = 0

	if cargo_capacity <= 0 or manifest.is_empty():
		return false

	var total_purchase_cost: float = 0.0

	for item_id: String in manifest.keys():
		var cargo_entry: Dictionary = manifest[item_id]
		var requested_units: int = int(cargo_entry.get("units", 0))
		var is_resource: bool = bool(cargo_entry.get("is_resource", false))
		var purchase_price: float = float(cargo_entry.get("purchase_price", 0.0))
		if requested_units <= 0 or purchase_price <= 0.0:
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

		var purchase_cost: float = purchase_price * float(units)
		if total_purchase_cost + purchase_cost > credits + 0.001:
			var affordable_units: int = _get_affordable_units(
				purchase_price,
				credits - total_purchase_cost
			)
			units = mini(units, affordable_units)
			if units <= 0:
				continue
			purchase_cost = purchase_price * float(units)

		cargo_manifest[item_id] = {
			"units": units,
			"is_resource": is_resource,
			"purchase_price": purchase_price
		}
		cargo_units += units
		total_purchase_cost += purchase_cost

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

	if cargo_units <= 0:
		return false

	credits -= total_purchase_cost
	return true

func _remain_docked(delta: float) -> void:
	var was_docked: bool = travel_state == TravelState.DOCKED
	super._remain_docked(delta)

	if was_docked and travel_state == TravelState.SELECT_DESTINATION:
		_unload_cargo()
		cargo_manifest.clear()
		cargo_units = 0
		cargo_origin_station_id = ""
		cargo_route_distance = 0.0

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

		var base_value: float = _get_item_base_value(
			destination_station,
			item_id,
			is_resource
		)
		var sale_price: float = _get_route_sale_price(
			destination_station,
			item_id,
			base_value,
			cargo_route_distance
		)
		credits += sale_price * float(units)

		var current_supply: float = float(destination_station.market.supply.get(item_id, 0.0))
		destination_station.market.supply[item_id] = current_supply + float(units)
		_update_market_price_for_item(
			destination_station.market,
			item_id,
			is_resource,
			destination_station
		)

func _refuel_for_trip(
	origin_station: GeneratedStationData,
	fuel_required: float
) -> bool:
	if fuel_required <= 0.0:
		return true

	if fuel_units >= fuel_required:
		return true

	var fuel_shortfall: float = fuel_required - fuel_units
	var fuel_supply: float = float(origin_station.market.supply.get("fuel", 0.0))
	var fuel_price: float = float(origin_station.market.current_prices.get("fuel", 45.0))
	if fuel_supply <= 0.0 or fuel_price <= 0.0:
		return false

	var affordable_fuel: float = floor(maxf(credits, 0.0) / fuel_price)
	var fuel_to_buy: float = minf(fuel_shortfall, minf(fuel_supply, affordable_fuel))
	if fuel_to_buy <= 0.0:
		return false

	var fuel_cost: float = fuel_to_buy * fuel_price
	fuel_units += fuel_to_buy
	credits -= fuel_cost
	origin_station.market.supply["fuel"] = maxf(0.0, fuel_supply - fuel_to_buy)
	return fuel_units >= fuel_required

func _calculate_fuel_required(route_distance: float) -> float:
	if fuel_consumption_per_10000_distance <= 0.0:
		return 0.0
	return (route_distance / 10000.0) * fuel_consumption_per_10000_distance

func _calculate_fuel_cost(
	origin_station: GeneratedStationData,
	fuel_required: float
) -> float:
	if fuel_required <= fuel_units:
		return 0.0

	var fuel_shortfall: float = fuel_required - fuel_units
	var fuel_price: float = float(origin_station.market.current_prices.get("fuel", 45.0))
	return fuel_shortfall * fuel_price

func _get_route_sale_price(
	station: GeneratedStationData,
	item_id: String,
	base_value: float,
	route_distance: float
) -> float:
	if station == null or station.market == null:
		return 0.0

	var market_price: float = float(station.market.current_prices.get(item_id, base_value))
	var safe_scale: float = maxf(distance_price_scale, 1.0)
	var distance_multiplier: float = 1.0 + clampf(route_distance / safe_scale, 0.0, 1.5)
	return market_price * distance_multiplier

func _get_affordable_units(unit_price: float, available_credits: float) -> int:
	if unit_price <= 0.0 or available_credits <= 0.0:
		return 0
	return int(floor(available_credits / unit_price))

func _get_station_distance(origin_id: String, destination_id: String) -> float:
	if space_system == null:
		return 0.0
	var origin_position: Vector2 = space_system.get_station_position(origin_id)
	var destination_position: Vector2 = space_system.get_station_position(destination_id)
	return origin_position.distance_to(destination_position)

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
	var is_exported: bool = _station_exports_item(station, item_id, is_resource)
	market_data.current_prices[item_id] = Market.new().calculate_price(
		base_value,
		supply,
		demand,
		is_exported
	)

func _station_exports_item(
	station: GeneratedStationData,
	item_id: String,
	is_resource: bool
) -> bool:
	if station == null or station.station_type == null:
		return false

	if is_resource:
		for resource_data: ResourceData in station.station_type.resource_exports:
			if resource_data != null and resource_data.id == item_id:
				return true
	else:
		for good_data: GoodData in station.station_type.good_exports:
			if good_data != null and good_data.id == item_id:
				return true

	return false

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
	if station == null or station.station_type == null:
		return false

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data != null and resource_data.id == resource_id:
			return true

	return false

func _station_imports_good(
	station: GeneratedStationData,
	good_id: String
) -> bool:
	if station == null or station.station_type == null:
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
