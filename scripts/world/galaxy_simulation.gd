class_name GalaxySimulation
extends Node

@export var simulation_seconds_per_real_second: float = 30.0
@export var simulation_tick_seconds: float = 60.0
@export var consumption_efficiency: float = 1.0
@export var civilian_ship_count_per_system: int = 6
@export var freighter_ship_count_per_system: int = 7
@export var civilian_speed: float = 260.0
@export var dock_duration: float = 6.0
@export var inter_system_transit_seconds: float = 45.0
@export var enable_debug_output: bool = true

var simulation_seconds: float = 0.0
var _tick_accumulator: float = 0.0
var _initialized: bool = false
var _production_progress: Dictionary = {}
var _traffic: Dictionary = {}

func _ready() -> void:
	call_deferred("_initialize")

func _process(delta: float) -> void:
	if not _initialized:
		return

	var simulated_delta: float = delta * simulation_seconds_per_real_second
	simulation_seconds += simulated_delta
	_tick_accumulator += simulated_delta

	_advance_system_time(simulated_delta)
	_advance_traffic(simulated_delta)

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

func _simulation_tick(simulated_delta: float) -> void:
	var extracted_units: float = 0.0
	var consumed_units: float = 0.0
	var produced_batches: int = 0

	for system_id: String in GalaxyState.get_all_system_ids():
		var system: GeneratedSystemData = GalaxyState.get_system(system_id)
		for station: GeneratedStationData in system.stations:
			if station == null or station.market == null or station.station_type == null:
				continue
			extracted_units += _process_resource_extraction(system, station, simulated_delta)
			consumed_units += _consume_station_demand(station, simulated_delta)
			produced_batches += _process_station_production(station, simulated_delta)
			_update_station_prices(station)

	if enable_debug_output:
		print("Galaxy economy tick | Sim %.1fh | Extracted %.2f | Consumed %.2f | Produced %d" % [
			simulation_seconds / 3600.0,
			extracted_units,
			consumed_units,
			produced_batches
		])

func _process_resource_extraction(system: GeneratedSystemData, station: GeneratedStationData, simulated_delta: float) -> float:
	if station.station_type.resource_extraction_rate <= 0.0:
		return 0.0

	var planet: GeneratedPlanetData = _get_planet_by_id(system, station.planet_id)
	if planet == null:
		return 0.0

	var simulated_hours: float = simulated_delta / 3600.0
	var extracted_units: float = 0.0

	for resource_data: ResourceData in station.station_type.resource_extraction:
		if resource_data == null:
			continue

		var abundance: float = float(planet.resource_abundance.get(resource_data.id, 0.0))
		var extraction_rate: float = station.station_type.resource_extraction_rate * clampf(abundance, 0.0, 1.0)
		var extracted_amount: float = extraction_rate * simulated_hours
		if extracted_amount <= 0.0:
			continue

		var current_supply: float = float(station.market.supply.get(resource_data.id, 0.0))
		station.market.supply[resource_data.id] = current_supply + extracted_amount
		extracted_units += extracted_amount

	return extracted_units

func _consume_station_demand(station: GeneratedStationData, simulated_delta: float) -> float:
	var simulated_hours: float = simulated_delta / 3600.0
	var consumed_units: float = 0.0

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data == null:
			continue
		var demand: float = float(station.market.demand.get(resource_data.id, 0.0))
		var requested_units: float = demand * simulated_hours * consumption_efficiency
		var current_supply: float = float(station.market.supply.get(resource_data.id, 0.0))
		var actual_units: float = minf(current_supply, maxf(requested_units, 0.0))
		station.market.supply[resource_data.id] = maxf(0.0, current_supply - actual_units)
		consumed_units += actual_units

	for good_data: GoodData in station.station_type.good_imports:
		if good_data == null:
			continue
		var demand: float = float(station.market.demand.get(good_data.id, 0.0))
		var requested_units: float = demand * simulated_hours * consumption_efficiency
		var current_supply: float = float(station.market.supply.get(good_data.id, 0.0))
		var actual_units: float = minf(current_supply, maxf(requested_units, 0.0))
		station.market.supply[good_data.id] = maxf(0.0, current_supply - actual_units)
		consumed_units += actual_units

	return consumed_units

func _process_station_production(station: GeneratedStationData, simulated_delta: float) -> int:
	var completed_batches: int = 0

	for recipe: ProductionRecipeData in station.station_type.production_recipes:
		if recipe == null or recipe.output == null or recipe.production_time <= 0.0:
			continue

		var station_progress: Dictionary = _production_progress.get(station.id, {}) as Dictionary
		var progress: float = float(station_progress.get(recipe.id, 0.0))

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

func _has_recipe_inputs(station: GeneratedStationData, recipe: ProductionRecipeData) -> bool:
	for ingredient: RecipeIngredientData in recipe.inputs:
		if ingredient == null or ingredient.quantity <= 0.0:
			continue
		var item_id: String = _get_ingredient_id(ingredient)
		if item_id.is_empty():
			return false
		var supply: float = float(station.market.supply.get(item_id, 0.0))
		if supply < ingredient.quantity:
			return false
	return true

func _consume_recipe_inputs(station: GeneratedStationData, recipe: ProductionRecipeData) -> void:
	for ingredient: RecipeIngredientData in recipe.inputs:
		if ingredient == null or ingredient.quantity <= 0.0:
			continue
		var item_id: String = _get_ingredient_id(ingredient)
		if item_id.is_empty():
			continue
		var current_supply: float = float(station.market.supply.get(item_id, 0.0))
		station.market.supply[item_id] = maxf(0.0, current_supply - ingredient.quantity)

func _add_recipe_output(station: GeneratedStationData, recipe: ProductionRecipeData) -> void:
	var output_id: String = recipe.output.id
	var current_supply: float = float(station.market.supply.get(output_id, 0.0))
	station.market.supply[output_id] = current_supply + recipe.output_quantity

func _get_ingredient_id(ingredient: RecipeIngredientData) -> String:
	if ingredient.resource != null:
		return ingredient.resource.id
	if ingredient.good != null:
		return ingredient.good.id
	return ""

func _update_station_prices(station: GeneratedStationData) -> void:
	var market: Market = Market.new()

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data != null:
			_update_price_for_resource(station, market, resource_data)
	for resource_data: ResourceData in station.station_type.resource_exports:
		if resource_data != null:
			_update_price_for_resource(station, market, resource_data)
	for good_data: GoodData in station.station_type.good_imports:
		if good_data != null:
			_update_price_for_good(station, market, good_data)
	for good_data: GoodData in station.station_type.good_exports:
		if good_data != null:
			_update_price_for_good(station, market, good_data)

func _update_price_for_resource(station: GeneratedStationData, market: Market, resource_data: ResourceData) -> void:
	var supply: float = float(station.market.supply.get(resource_data.id, 0.0))
	var demand: float = float(station.market.demand.get(resource_data.id, 0.0))
	station.market.current_prices[resource_data.id] = market.calculate_price(
		resource_data.base_value,
		supply,
		demand,
		_station_exports_resource(station, resource_data.id)
	)

func _update_price_for_good(station: GeneratedStationData, market: Market, good_data: GoodData) -> void:
	var supply: float = float(station.market.supply.get(good_data.id, 0.0))
	var demand: float = float(station.market.demand.get(good_data.id, 0.0))
	station.market.current_prices[good_data.id] = market.calculate_price(
		good_data.base_value,
		supply,
		demand,
		_station_exports_good(station, good_data.id)
	)

func _station_exports_resource(station: GeneratedStationData, resource_id: String) -> bool:
	for resource_data: ResourceData in station.station_type.resource_exports:
		if resource_data != null and resource_data.id == resource_id:
			return true
	return false

func _station_exports_good(station: GeneratedStationData, good_id: String) -> bool:
	for good_data: GoodData in station.station_type.good_exports:
		if good_data != null and good_data.id == good_id:
			return true
	return false

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
		var score: float = _calculate_traffic_destination_score(
			origin_station,
			GalaxyState.get_system(String(candidate["system_id"])),
			String(candidate["station_id"]),
			float(candidate["distance"]),
			bool(record.get("is_freighter", false))
		)
		if score > best_score:
			best_score = score
			selected = candidate

	var destination_system_id: String = String(selected["system_id"])
	var destination_station_id: String = String(selected["station_id"])
	var destination_system: GeneratedSystemData = GalaxyState.get_system(destination_system_id)
	var destination_station: GeneratedStationData = _get_station_by_id(destination_system, destination_station_id)

	if bool(record.get("is_freighter", false)):
		_prepare_freighter_cargo(record, origin_station, destination_station)

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
	var destination_station: GeneratedStationData = _get_station_by_id(destination_system, destination_station_id)
	if destination_station == null:
		return -INF
	if not is_freighter:
		return 1000.0 - distance * 0.001

	var score: float = 0.0
	for resource_data: ResourceData in origin_station.station_type.resource_exports:
		if resource_data == null or not _station_imports_resource(destination_station, resource_data.id):
			continue
		var origin_price: float = float(origin_station.market.current_prices.get(resource_data.id, resource_data.base_value))
		var destination_price: float = float(destination_station.market.current_prices.get(resource_data.id, resource_data.base_value))
		score = maxf(score, destination_price - origin_price)
	for good_data: GoodData in origin_station.station_type.good_exports:
		if good_data == null or not _station_imports_good(destination_station, good_data.id):
			continue
		var origin_price: float = float(origin_station.market.current_prices.get(good_data.id, good_data.base_value))
		var destination_price: float = float(destination_station.market.current_prices.get(good_data.id, good_data.base_value))
		score = maxf(score, destination_price - origin_price)
	return score - (distance * 0.0001)

func _prepare_freighter_cargo(record: Dictionary, origin_station: GeneratedStationData, destination_station: GeneratedStationData) -> void:
	if destination_station == null:
		record["cargo"] = {}
		return

	var remaining_capacity: int = 250
	var remaining_credits: float = float(record.get("credits", 25000.0))
	var cargo: Dictionary = {}

	for resource_data: ResourceData in origin_station.station_type.resource_exports:
		if remaining_capacity <= 0:
			break
		if resource_data == null or not _station_imports_resource(destination_station, resource_data.id):
			continue
		var origin_price: float = float(origin_station.market.current_prices.get(resource_data.id, resource_data.base_value))
		var destination_price: float = float(destination_station.market.current_prices.get(resource_data.id, resource_data.base_value))
		if destination_price <= origin_price or origin_price <= 0.0:
			continue
		var available_supply: int = int(floor(float(origin_station.market.supply.get(resource_data.id, 0.0))))
		var affordable_units: int = int(floor(remaining_credits / origin_price))
		var units: int = mini(100, mini(remaining_capacity, mini(available_supply, affordable_units)))
		if units <= 0:
			continue
		cargo[resource_data.id] = {
			"units": units,
			"purchase_price": origin_price,
			"base_value": resource_data.base_value,
			"is_resource": true
		}
		remaining_capacity -= units
		remaining_credits -= origin_price * float(units)
		origin_station.market.supply[resource_data.id] = maxf(0.0, float(origin_station.market.supply.get(resource_data.id, 0.0)) - float(units))

	for good_data: GoodData in origin_station.station_type.good_exports:
		if remaining_capacity <= 0:
			break
		if good_data == null or not _station_imports_good(destination_station, good_data.id):
			continue
		var origin_price: float = float(origin_station.market.current_prices.get(good_data.id, good_data.base_value))
		var destination_price: float = float(destination_station.market.current_prices.get(good_data.id, good_data.base_value))
		if destination_price <= origin_price or origin_price <= 0.0:
			continue
		var available_supply: int = int(floor(float(origin_station.market.supply.get(good_data.id, 0.0))))
		var affordable_units: int = int(floor(remaining_credits / origin_price))
		var units: int = mini(100, mini(remaining_capacity, mini(available_supply, affordable_units)))
		if units <= 0:
			continue
		cargo[good_data.id] = {
			"units": units,
			"purchase_price": origin_price,
			"base_value": good_data.base_value,
			"is_resource": false
		}
		remaining_capacity -= units
		remaining_credits -= origin_price * float(units)
		origin_station.market.supply[good_data.id] = maxf(0.0, float(origin_station.market.supply.get(good_data.id, 0.0)) - float(units))

	record["cargo"] = cargo
	record["credits"] = remaining_credits

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

func _complete_freighter_trade(record: Dictionary, destination_station: GeneratedStationData) -> void:
	var cargo: Dictionary = record.get("cargo", {}) as Dictionary
	if destination_station == null or destination_station.market == null:
		return

	var revenue: float = 0.0
	for item_id: String in cargo.keys():
		var cargo_entry: Dictionary = cargo[item_id]
		var units: int = int(cargo_entry.get("units", 0))
		var base_value: float = float(cargo_entry.get("base_value", 0.0))
		if units <= 0 or base_value <= 0.0:
			continue
		var market_price: float = float(destination_station.market.current_prices.get(item_id, base_value))
		var sale_price: float = market_price * (1.0 + clampf(GalaxyState.INTER_SYSTEM_DISTANCE / 40000.0, 0.0, 1.5))
		revenue += sale_price * float(units)
		var current_supply: float = float(destination_station.market.supply.get(item_id, 0.0))
		destination_station.market.supply[item_id] = current_supply + float(units)

	record["credits"] = float(record.get("credits", 0.0)) + revenue
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
