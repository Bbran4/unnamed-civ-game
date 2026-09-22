extends Node

@export var simulation_seconds_per_real_second: float = 30.0
@export var traffic_simulation_seconds_per_real_second: float = 1.0
@export var simulation_tick_seconds: float = 10.0
@export var consumption_efficiency: float = 1.0
@export var civilian_ship_count_per_system: int = 6
@export var freighter_ship_count_per_system: int = 7
@export var civilian_speed: float = 260.0
@export var dock_duration: float = 6.0
@export var inter_system_transit_seconds: float = 45.0
@export var enable_debug_output: bool = true
@export var station_market_report_interval: float = 5.0
@export var freighter_cargo_capacity: int = 250
@export var freighter_starting_credits: float = 25000.0
@export var freighter_fuel_capacity: float = 100.0
@export var freighter_starting_fuel: float = 100.0
@export var freighter_fuel_consumption_per_10000_distance: float = 5.0
@export var freighter_maximum_units_per_cargo_type: int = 100
@export var freighter_trade_reserve_seconds: float = 120.0

var simulation_seconds: float = 0.0
var _tick_accumulator: float = 0.0
var _initialized: bool = false
var _production_progress: Dictionary = {}
var _traffic: Dictionary = {}
var _station_market_report_accumulator: float = 0.0

func _ready() -> void:
	call_deferred("_initialize")

func _process(delta: float) -> void:
	if not _initialized:
		return

	var simulated_delta: float = delta * simulation_seconds_per_real_second
	var traffic_delta: float = delta * traffic_simulation_seconds_per_real_second
	simulation_seconds += simulated_delta
	_tick_accumulator += simulated_delta

	_advance_system_time(simulated_delta)
	_advance_traffic(traffic_delta)
	_station_market_report_accumulator += delta
	while _station_market_report_accumulator >= station_market_report_interval:
		_station_market_report_accumulator -= station_market_report_interval
		_print_station_market_report()
		_print_freighter_report()

	while _tick_accumulator >= simulation_tick_seconds:
		_tick_accumulator -= simulation_tick_seconds
		_simulation_tick(simulation_tick_seconds)

func _initialize() -> void:
	for system_id: String in GalaxyState.get_all_system_ids():
		GalaxyState.get_system(system_id)
		_create_initial_traffic_for_system(system_id)

	_initialized = true
	print("Galaxy simulation initialized: %d systems, %d traffic records." % [
		GalaxyState.get_all_system_ids().size(),
		_traffic.size()
	])

func _advance_system_time(simulated_delta: float) -> void:
	for system_id: String in GalaxyState.get_all_system_ids():
		var system: GeneratedSystemData = GalaxyState.get_system(system_id)
		system.simulation_time += simulated_delta

func _print_station_market_report() -> void:
	print("========== STATION MARKET REPORT ==========")

	for system_id: String in GalaxyState.get_all_system_ids():
		var system: GeneratedSystemData = GalaxyState.get_system(system_id)

		for station: GeneratedStationData in system.stations:
			if station == null or station.market == null:
				continue

			var market_lines: Array[String] = []

			for item_id: String in station.market.supply.keys():
				var supply_value: float = float(
					station.market.supply.get(item_id, 0.0)
				)
				var demand_value: float = float(
					station.market.demand.get(item_id, 0.0)
				)

				if supply_value <= 0.0 and demand_value <= 0.0:
					continue

				var price_value: float = float(
					station.market.current_prices.get(item_id, 0.0)
				)
				market_lines.append(
					"%s S=%.2f D=%.2f P=%.2f"
					% [
						item_id,
						supply_value,
						demand_value,
						price_value
					]
				)

			market_lines.sort()

			print(
				"%s | %s | System: %s"
				% [
					station.display_name,
					" | ".join(market_lines),
					system.display_name
				]
			)

func _print_freighter_report() -> void:
	print("========== FREIGHTER REPORT ==========")

	for traffic_id: String in _traffic.keys():
		var record: Dictionary = _traffic[traffic_id]
		if not bool(record.get("is_freighter", false)):
			continue

		var current_system_id: String = String(
			record.get("system_id", "")
		)
		var current_system: GeneratedSystemData = GalaxyState.get_system(
			current_system_id
		)
		var origin_station_id: String = String(
			record.get("origin_station_id", "")
		)
		var destination_system_id: String = String(
			record.get("destination_system_id", "")
		)
		var destination_station_id: String = String(
			record.get("destination_station_id", "")
		)

		var origin_station: GeneratedStationData = _get_station_by_id(
			current_system,
			origin_station_id
		)
		var origin_name: String = (
			origin_station.display_name
			if origin_station != null
			else origin_station_id
		)

		var destination_name: String = "Docked"
		if not destination_station_id.is_empty():
			var destination_system: GeneratedSystemData = GalaxyState.get_system(
				destination_system_id
			)
			var destination_station: GeneratedStationData = _get_station_by_id(
				destination_system,
				destination_station_id
			)
			if destination_station != null:
				destination_name = destination_station.display_name

		var cargo: Dictionary = record.get("cargo", {}) as Dictionary
		var cargo_units: int = 0
		for item_id: String in cargo.keys():
			var cargo_entry: Dictionary = cargo[item_id]
			cargo_units += int(cargo_entry.get("units", 0))

		print(
			"FREIGHT | %s | %s -> %s | State: %s | Cargo: %d | Credits: %.0f | Fuel: %.1f"
			% [
				traffic_id,
				origin_name,
				destination_name,
				String(record.get("state", "docked")),
				cargo_units,
				float(record.get("credits", 0.0)),
				float(record.get("fuel", 0.0))
			]
		)

func _simulation_tick(simulated_delta: float) -> void:
	var extracted_units: float = 0.0
	var consumed_units: float = 0.0
	var produced_batches: int = 0

	for system_id: String in GalaxyState.get_all_system_ids():
		var system: GeneratedSystemData = GalaxyState.get_system(system_id)

		for station: GeneratedStationData in system.stations:
			if station == null or station.market == null or station.station_type == null:
				continue

			extracted_units += _process_resource_extraction(
				system,
				station,
				simulated_delta
			)
			consumed_units += _consume_station_operational_demand(
				station,
				simulated_delta
			)
			produced_batches += _process_station_production(
				station,
				simulated_delta
			)

	for system_id: String in GalaxyState.get_all_system_ids():
		var system: GeneratedSystemData = GalaxyState.get_system(system_id)

		for station: GeneratedStationData in system.stations:
			if station == null or station.market == null:
				continue

			_refresh_station_demand(station)
			_update_station_prices(station)

	if enable_debug_output:
		print(
			"Economy tick | Sim %.1fs | Extracted %.3f | Consumed %.3f | Produced %d"
			% [
				simulation_seconds,
				extracted_units,
				consumed_units,
				produced_batches
			]
		)

func _process_resource_extraction(
	system: GeneratedSystemData,
	station: GeneratedStationData,
	simulated_delta: float
) -> float:
	if station == null or station.station_type == null or station.market == null:
		return 0.0
	if station.station_type.resource_extraction_rate <= 0.0:
		return 0.0

	var planet: GeneratedPlanetData = _get_planet_by_id(system, station.planet_id)
	if planet == null:
		return 0.0

	var extracted_units: float = 0.0

	for resource_data: ResourceData in station.station_type.resource_extraction:
		if resource_data == null:
			continue

		var abundance: float = clampf(
			float(planet.resource_abundance.get(resource_data.id, 0.0)),
			0.0,
			1.0
		)
		var extraction_rate_per_second: float = (
			station.station_type.resource_extraction_rate * abundance
		)
		var extracted_amount: float = extraction_rate_per_second * simulated_delta

		if extracted_amount <= 0.0:
			continue

		var current_supply: float = float(
			station.market.supply.get(resource_data.id, 0.0)
		)
		station.market.supply[resource_data.id] = current_supply + extracted_amount
		extracted_units += extracted_amount

	return extracted_units

func _consume_station_operational_demand(
	station: GeneratedStationData,
	simulated_delta: float
) -> float:
	if station == null or station.market == null:
		return 0.0

	var consumed_units: float = 0.0

	for item_id: String in station.market.operational_demand.keys():
		var demand_rate: float = float(
			station.market.operational_demand.get(item_id, 0.0)
		)
		var requested_units: float = (
			demand_rate * simulated_delta * consumption_efficiency
		)
		var current_supply: float = float(
			station.market.supply.get(item_id, 0.0)
		)
		var actual_units: float = minf(
			current_supply,
			maxf(requested_units, 0.0)
		)

		station.market.supply[item_id] = maxf(
			0.0,
			current_supply - actual_units
		)
		consumed_units += actual_units

	return consumed_units

func _process_station_production(
	station: GeneratedStationData,
	simulated_delta: float
) -> int:
	var completed_batches: int = 0

	for recipe: ProductionRecipeData in station.station_type.production_recipes:
		if recipe == null or recipe.output == null:
			continue
		if recipe.production_time <= 0.0:
			continue

		var station_progress: Dictionary = _production_progress.get(
			station.id,
			{}
		) as Dictionary
		var progress: float = float(
			station_progress.get(recipe.id, 0.0)
		)

		if _has_recipe_inputs(station, recipe):
			progress += simulated_delta

		while progress >= recipe.production_time:
			if not _has_recipe_inputs(station, recipe):
				break

			_consume_recipe_inputs(station, recipe)
			_add_recipe_output(station, recipe)
			progress -= recipe.production_time
			completed_batches += 1

		station_progress[recipe.id] = progress
		_production_progress[station.id] = station_progress

	return completed_batches

func _has_recipe_inputs(
	station: GeneratedStationData,
	recipe: ProductionRecipeData
) -> bool:
	for ingredient: RecipeIngredientData in recipe.inputs:
		if ingredient == null or ingredient.quantity <= 0.0:
			continue

		var item_id: String = _get_ingredient_id(ingredient)
		if item_id.is_empty():
			return false

		var supply: float = float(
			station.market.supply.get(item_id, 0.0)
		)
		if supply < ingredient.quantity:
			return false

	return true

func _consume_recipe_inputs(
	station: GeneratedStationData,
	recipe: ProductionRecipeData
) -> void:
	for ingredient: RecipeIngredientData in recipe.inputs:
		if ingredient == null or ingredient.quantity <= 0.0:
			continue

		var item_id: String = _get_ingredient_id(ingredient)
		if item_id.is_empty():
			continue

		var current_supply: float = float(
			station.market.supply.get(item_id, 0.0)
		)
		station.market.supply[item_id] = maxf(
			0.0,
			current_supply - ingredient.quantity
		)

func _add_recipe_output(
	station: GeneratedStationData,
	recipe: ProductionRecipeData
) -> void:
	var output_id: String = recipe.output.id
	var current_supply: float = float(
		station.market.supply.get(output_id, 0.0)
	)
	station.market.supply[output_id] = (
		current_supply + recipe.output_quantity
	)

func _get_ingredient_id(ingredient: RecipeIngredientData) -> String:
	if ingredient.resource != null:
		return ingredient.resource.id
	if ingredient.good != null:
		return ingredient.good.id
	return ""

func _refresh_station_demand(station: GeneratedStationData) -> void:
	if station == null or station.market == null:
		return

	var market: Market = Market.new()
	market.refresh_demand(station.market)

func _update_station_prices(station: GeneratedStationData) -> void:
	if station == null or station.market == null:
		return

	var market: Market = Market.new()

	for item_id: String in station.market.supply.keys():
		var base_value: float = float(
			station.market.base_values.get(item_id, 1.0)
		)
		var supply: float = float(
			station.market.supply.get(item_id, 0.0)
		)
		var demand_rate: float = float(
			station.market.demand_rate.get(item_id, 0.0)
		)

		station.market.current_prices[item_id] = market.calculate_price(
			base_value,
			supply,
			demand_rate
		)

func _create_initial_traffic_for_system(system_id: String) -> void:
	for civilian_index: int in range(civilian_ship_count_per_system):
		_create_traffic_record(system_id, false, civilian_index)
	for freighter_index: int in range(freighter_ship_count_per_system):
		_create_traffic_record(system_id, true, freighter_index)

func _create_traffic_record(system_id: String, is_freighter: bool, index: int) -> void:
	var system: GeneratedSystemData = GalaxyState.get_system(system_id)
	if system.stations.is_empty():
		return

	var station_index: int = index % system.stations.size()
	var station: GeneratedStationData = system.stations[station_index]
	var prefix: String = "freighter" if is_freighter else "civilian"
	var traffic_id: String = "%s_%s_%d" % [prefix, system_id, index]

	_traffic[traffic_id] = {
		"id": traffic_id,
		"is_freighter": is_freighter,
		"system_id": system_id,
		"origin_station_id": station.id,
		"destination_system_id": system_id,
		"destination_station_id": "",
		"state": "docked",
		"progress": 0.0,
		"travel_duration": 0.0,
		"dock_remaining": float((index % 6) + 1),
		"credits": 25000.0 if is_freighter else 0.0,
		"fuel": 100.0 if is_freighter else 0.0,
		"cargo": {}
	}

func _advance_traffic(simulated_delta: float) -> void:
	for traffic_id: String in _traffic.keys():
		var record: Dictionary = _traffic[traffic_id]
		match String(record.get("state", "docked")):
			"docked":
				_advance_docked_record(record, simulated_delta)
			"local_travel", "inter_system_travel":
				_advance_travelling_record(record, simulated_delta)
		_traffic[traffic_id] = record

func _advance_docked_record(record: Dictionary, simulated_delta: float) -> void:
	var dock_remaining: float = float(record.get("dock_remaining", 0.0)) - simulated_delta
	record["dock_remaining"] = dock_remaining
	if dock_remaining > 0.0:
		return
	_select_traffic_destination(record)

func _select_traffic_destination(record: Dictionary) -> void:
	var system_id: String = String(record.get("system_id", ""))
	var system: GeneratedSystemData = GalaxyState.get_system(system_id)
	var origin_station_id: String = String(record.get("origin_station_id", ""))
	var origin_station: GeneratedStationData = _get_station_by_id(system, origin_station_id)
	if origin_station == null or system.stations.size() < 2:
		record["dock_remaining"] = dock_duration
		return

	var candidates: Array[Dictionary] = []
	for station: GeneratedStationData in system.stations:
		if station.id != origin_station.id:
			candidates.append({
				"system_id": system_id,
				"station_id": station.id,
				"distance": _get_station_distance(system, origin_station.id, station.id)
			})

	if bool(record.get("is_freighter", false)):
		for remote_system_id: String in GalaxyState.get_all_system_ids():
			if remote_system_id == system_id:
				continue
			var remote_system: GeneratedSystemData = GalaxyState.get_system(remote_system_id)
			for station: GeneratedStationData in remote_system.stations:
				candidates.append({
					"system_id": remote_system_id,
					"station_id": station.id,
					"distance": GalaxyState.INTER_SYSTEM_DISTANCE
				})

	if candidates.is_empty():
		record["dock_remaining"] = dock_duration
		return

	var selected: Dictionary = candidates[0]
	var best_score: float = -INF
	for candidate: Dictionary in candidates:
		var candidate_system: GeneratedSystemData = GalaxyState.get_system(
			String(candidate["system_id"])
		)
		var candidate_distance: float = float(candidate["distance"])
		var score: float = _calculate_traffic_destination_score(
			origin_station,
			candidate_system,
			String(candidate["station_id"]),
			candidate_distance,
			bool(record.get("is_freighter", false))
		)

		if bool(record.get("is_freighter", false)):
			var candidate_fuel_required: float = _get_freighter_trip_fuel_required(
				system_id,
				String(candidate["system_id"]),
				candidate_distance
			)
			if not _can_freighter_fuel_trip(
				record,
				origin_station,
				candidate_fuel_required
			):
				continue

		if score > best_score:
			best_score = score
			selected = candidate

	var destination_system_id: String = String(selected["system_id"])
	var destination_station_id: String = String(selected["station_id"])
	var destination_system: GeneratedSystemData = GalaxyState.get_system(destination_system_id)
	var destination_station: GeneratedStationData = _get_station_by_id(destination_system, destination_station_id)

	if bool(record.get("is_freighter", false)):
		if best_score <= 0.0:
			record["dock_remaining"] = dock_duration
			return

		var fuel_required: float = _get_freighter_trip_fuel_required(
			system_id,
			destination_system_id,
			float(selected["distance"])
		)
		if not _ensure_freighter_fuel(
			record,
			origin_station,
			fuel_required
		):
			record["dock_remaining"] = dock_duration
			return

		_prepare_freighter_cargo(
			record,
			origin_station,
			destination_station
		)
		var cargo: Dictionary = record.get("cargo", {}) as Dictionary
		if cargo.is_empty():
			record["dock_remaining"] = dock_duration
			return

	record["destination_system_id"] = destination_system_id
	record["destination_station_id"] = destination_station_id
	record["progress"] = 0.0

	if destination_system_id == system_id:
		var distance: float = float(selected["distance"])
		record["travel_duration"] = maxf(10.0, distance / maxf(civilian_speed, 1.0))
		record["state"] = "local_travel"
	else:
		record["travel_duration"] = inter_system_transit_seconds
		record["state"] = "inter_system_travel"

func _calculate_traffic_destination_score(
	origin_station: GeneratedStationData,
	destination_system: GeneratedSystemData,
	destination_station_id: String,
	distance: float,
	is_freighter: bool
) -> float:
	var destination_station: GeneratedStationData = _get_station_by_id(
		destination_system,
		destination_station_id
	)
	if destination_station == null:
		return -INF

	if not is_freighter:
		return 1000.0 - distance * 0.001

	return _calculate_best_trade_profit(
		origin_station,
		destination_station,
		distance,
		distance >= GalaxyState.INTER_SYSTEM_DISTANCE
	)

func _calculate_best_trade_profit(
	origin_station: GeneratedStationData,
	destination_station: GeneratedStationData,
	distance: float,
	is_inter_system: bool
) -> float:
	if origin_station == null or destination_station == null:
		return -INF
	if origin_station.market == null or destination_station.market == null:
		return -INF

	var best_profit: float = -INF
	var fuel_required: float = (
		GalaxyState.INTER_SYSTEM_FUEL_COST
		if is_inter_system
		else _calculate_freighter_fuel_required(distance)
	)
	var fuel_cost: float = _calculate_freighter_fuel_cost(
		origin_station,
		fuel_required
	)

	for item_id: String in origin_station.market.supply.keys():
		var exportable_units: float = _get_exportable_units(
			origin_station,
			item_id
		)
		var destination_demand: float = float(
			destination_station.market.demand.get(item_id, 0.0)
		)

		if exportable_units < 1.0 or destination_demand <= 0.0:
			continue

		var origin_price: float = float(
			origin_station.market.current_prices.get(item_id, 0.0)
		)
		var destination_price: float = float(
			destination_station.market.current_prices.get(item_id, 0.0)
		)

		if origin_price <= 0.0 or destination_price <= origin_price:
			continue

		var tradable_units: float = minf(
			exportable_units,
			destination_demand
		)
		var trade_profit: float = (
			(destination_price - origin_price)
			* tradable_units
		) - fuel_cost

		if trade_profit > best_profit:
			best_profit = trade_profit

	return best_profit

func _prepare_freighter_cargo(
	record: Dictionary,
	origin_station: GeneratedStationData,
	destination_station: GeneratedStationData
) -> void:
	if origin_station == null or destination_station == null:
		record["cargo"] = {}
		return

	var remaining_capacity: int = maxi(freighter_cargo_capacity, 0)
	var remaining_credits: float = maxf(
		float(record.get("credits", freighter_starting_credits)),
		0.0
	)
	var cargo: Dictionary = {}

	while remaining_capacity > 0 and remaining_credits > 0.0:
		var best_item_id: String = ""
		var best_profit_per_unit: float = 0.0
		var best_units: int = 0
		var best_origin_price: float = 0.0

		for item_id: String in origin_station.market.supply.keys():
			var exportable_units: float = _get_exportable_units(
				origin_station,
				item_id
			)
			var destination_demand: float = float(
				destination_station.market.demand.get(item_id, 0.0)
			)

			if exportable_units < 1.0 or destination_demand <= 0.0:
				continue

			var origin_price: float = float(
				origin_station.market.current_prices.get(item_id, 0.0)
			)
			var destination_price: float = float(
				destination_station.market.current_prices.get(item_id, 0.0)
			)

			if origin_price <= 0.0 or destination_price <= origin_price:
				continue

			var profit_per_unit: float = (
				destination_price - origin_price
			)
			var affordable_units: int = int(
				floor(remaining_credits / origin_price)
			)
			var available_units: int = int(floor(exportable_units))
			var demand_units: int = int(floor(destination_demand))
			var units: int = mini(
				remaining_capacity,
				mini(
					freighter_maximum_units_per_cargo_type,
					mini(
						available_units,
						mini(demand_units, affordable_units)
					)
				)
			)

			if profit_per_unit > best_profit_per_unit and units > 0:
				best_item_id = item_id
				best_profit_per_unit = profit_per_unit
				best_units = units
				best_origin_price = origin_price

		if best_item_id.is_empty() or best_units <= 0:
			break

		cargo[best_item_id] = {
			"units": best_units,
			"purchase_price": best_origin_price,
			"base_value": float(
				origin_station.market.base_values.get(
					best_item_id,
					best_origin_price
				)
			),
			"is_resource": _is_resource_id(best_item_id)
		}

		remaining_capacity -= best_units
		remaining_credits -= (
			best_origin_price * float(best_units)
		)

		var current_supply: float = float(
			origin_station.market.supply.get(best_item_id, 0.0)
		)
		origin_station.market.supply[best_item_id] = maxf(
			0.0,
			current_supply - float(best_units)
		)

	record["cargo"] = cargo
	record["credits"] = remaining_credits

func _get_exportable_units(
	station: GeneratedStationData,
	item_id: String
) -> float:
	if station == null or station.market == null:
		return 0.0

	var supply: float = float(
		station.market.supply.get(item_id, 0.0)
	)
	var demand_rate: float = float(
		station.market.demand_rate.get(item_id, 0.0)
	)
	var reserve: float = (
		demand_rate * freighter_trade_reserve_seconds
	)

	return maxf(supply - reserve, 0.0)

func _get_freighter_trip_fuel_required(
	origin_system_id: String,
	destination_system_id: String,
	distance: float
) -> float:
	if origin_system_id != destination_system_id:
		return GalaxyState.INTER_SYSTEM_FUEL_COST

	return _calculate_freighter_fuel_required(distance)

func _can_freighter_fuel_trip(
	record: Dictionary,
	origin_station: GeneratedStationData,
	fuel_required: float
) -> bool:
	if fuel_required <= 0.0:
		return true
	if origin_station == null or origin_station.market == null:
		return false

	var current_fuel: float = float(
		record.get("fuel", freighter_starting_fuel)
	)
	if current_fuel >= fuel_required:
		return true

	var fuel_shortfall: float = fuel_required - current_fuel
	var fuel_supply: float = float(
		origin_station.market.supply.get("fuel", 0.0)
	)
	var fuel_price: float = float(
		origin_station.market.current_prices.get("fuel", 0.0)
	)
	var credits: float = float(
		record.get("credits", freighter_starting_credits)
	)

	return (
		fuel_supply >= fuel_shortfall
		and fuel_price > 0.0
		and credits >= fuel_shortfall * fuel_price
	)

func _ensure_freighter_fuel(
	record: Dictionary,
	origin_station: GeneratedStationData,
	fuel_required: float
) -> bool:
	if fuel_required <= 0.0:
		return true

	var current_fuel: float = float(
		record.get("fuel", freighter_starting_fuel)
	)
	if current_fuel >= fuel_required:
		record["fuel"] = current_fuel - fuel_required
		return true

	var fuel_shortfall: float = fuel_required - current_fuel
	var fuel_supply: float = float(
		origin_station.market.supply.get("fuel", 0.0)
	)
	var fuel_price: float = float(
		origin_station.market.current_prices.get("fuel", 0.0)
	)

	if fuel_supply < fuel_shortfall or fuel_price <= 0.0:
		return false

	var fuel_cost: float = fuel_shortfall * fuel_price
	var credits: float = float(
		record.get("credits", freighter_starting_credits)
	)
	if credits < fuel_cost:
		return false

	origin_station.market.supply["fuel"] = maxf(
		0.0,
		fuel_supply - fuel_shortfall
	)
	record["credits"] = credits - fuel_cost
	record["fuel"] = 0.0

	return true

func _calculate_freighter_fuel_required(distance: float) -> float:
	if distance <= 0.0:
		return 0.0
	if freighter_fuel_consumption_per_10000_distance <= 0.0:
		return 0.0

	return (
		distance / 10000.0
	) * freighter_fuel_consumption_per_10000_distance

func _calculate_freighter_fuel_cost(
	origin_station: GeneratedStationData,
	fuel_required: float
) -> float:
	if origin_station == null or origin_station.market == null:
		return 0.0
	if fuel_required <= 0.0:
		return 0.0

	var fuel_price: float = float(
		origin_station.market.current_prices.get("fuel", 0.0)
	)

	return fuel_required * fuel_price

func _is_resource_id(item_id: String) -> bool:
	return ResourceLoader.exists(
		"res://data/economy/resources/%s.tres" % item_id
	)

func _advance_travelling_record(record: Dictionary, simulated_delta: float) -> void:
	var duration: float = maxf(float(record.get("travel_duration", 1.0)), 1.0)
	var progress: float = float(record.get("progress", 0.0)) + simulated_delta / duration
	if progress < 1.0:
		record["progress"] = clampf(progress, 0.0, 1.0)
		return

	var destination_system_id: String = String(record.get("destination_system_id", ""))
	var destination_station_id: String = String(record.get("destination_station_id", ""))
	var destination_system: GeneratedSystemData = GalaxyState.get_system(destination_system_id)
	var destination_station: GeneratedStationData = _get_station_by_id(destination_system, destination_station_id)

	record["system_id"] = destination_system_id
	record["origin_station_id"] = destination_station_id
	record["destination_station_id"] = ""
	record["progress"] = 0.0
	record["dock_remaining"] = dock_duration
	record["state"] = "docked"

	if bool(record.get("is_freighter", false)):
		_complete_freighter_trade(record, destination_station)

func _complete_freighter_trade(
	record: Dictionary,
	destination_station: GeneratedStationData
) -> void:
	var cargo: Dictionary = record.get("cargo", {}) as Dictionary
	if destination_station == null or destination_station.market == null:
		return

	var revenue: float = 0.0

	for item_id: String in cargo.keys():
		var cargo_entry: Dictionary = cargo[item_id]
		var units: int = int(cargo_entry.get("units", 0))
		var purchase_price: float = float(
			cargo_entry.get("purchase_price", 0.0)
		)

		if units <= 0 or purchase_price <= 0.0:
			continue

		var sale_price: float = float(
			destination_station.market.current_prices.get(
				item_id,
				purchase_price
			)
		)
		revenue += sale_price * float(units)

		var current_supply: float = float(
			destination_station.market.supply.get(item_id, 0.0)
		)
		destination_station.market.supply[item_id] = (
			current_supply + float(units)
		)

	record["credits"] = (
		float(record.get("credits", freighter_starting_credits))
		+ revenue
	)
	record["cargo"] = {}

func get_traffic_for_system(system_id: String) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for traffic_id: String in _traffic.keys():
		var record: Dictionary = _traffic[traffic_id]
		if String(record.get("system_id", "")) == system_id:
			records.append(record)
	return records

func get_traffic_record(traffic_id: String) -> Dictionary:
	return _traffic.get(traffic_id, {}) as Dictionary

func _get_planet_by_id(system: GeneratedSystemData, planet_id: String) -> GeneratedPlanetData:
	for planet: GeneratedPlanetData in system.planets:
		if planet.id == planet_id:
			return planet
	return null

func _get_station_by_id(system: GeneratedSystemData, station_id: String) -> GeneratedStationData:
	for station: GeneratedStationData in system.stations:
		if station.id == station_id:
			return station
	return null

func _get_station_distance(system: GeneratedSystemData, origin_station_id: String, destination_station_id: String) -> float:
	var origin_position: Vector2 = GalaxyState.get_station_position(system.id, origin_station_id)
	var destination_position: Vector2 = GalaxyState.get_station_position(system.id, destination_station_id)
	return origin_position.distance_to(destination_position)

func _station_imports_resource(station: GeneratedStationData, resource_id: String) -> bool:
	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data != null and resource_data.id == resource_id:
			return true
	return false

func _station_imports_good(station: GeneratedStationData, good_id: String) -> bool:
	for good_data: GoodData in station.station_type.good_imports:
		if good_data != null and good_data.id == good_id:
			return true
	return false
