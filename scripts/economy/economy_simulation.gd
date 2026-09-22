class_name EconomySimulation
extends Node

@export var simulation_seconds_per_real_second: float = 30.0
@export var simulation_tick_seconds: float = 60.0
@export var consumption_efficiency: float = 1.0
@export var enable_debug_output: bool = true

var space_system: SpaceSystem
var simulation_seconds: float = 0.0
var _tick_accumulator: float = 0.0
var production_progress: Dictionary = {}

func _ready() -> void:
	call_deferred("_initialize")

func _process(delta: float) -> void:
	if space_system == null:
		return

	var simulated_delta: float = delta * simulation_seconds_per_real_second
	simulation_seconds += simulated_delta
	_tick_accumulator += simulated_delta

	while _tick_accumulator >= simulation_tick_seconds:
		_tick_accumulator -= simulation_tick_seconds
		_simulation_tick(simulation_tick_seconds)

func _initialize() -> void:
	space_system = get_parent() as SpaceSystem
	if space_system == null:
		push_error("EconomySimulation must be a child of SpaceSystem.")
		return

	production_progress.clear()
	print("Economy simulation initialized.")

func _simulation_tick(simulated_delta: float) -> void:
	if space_system == null:
		return

	var production_batches: int = 0
	var consumed_units: float = 0.0
	var extracted_units: float = 0.0

	for station: GeneratedStationData in space_system.generated_system.stations:
		if station == null or station.market == null or station.station_type == null:
			continue

		extracted_units += _process_resource_extraction(station, simulated_delta)
		consumed_units += _consume_station_demand(station, simulated_delta)
		production_batches += _process_station_production(station, simulated_delta)
		_update_station_prices(station)

	if enable_debug_output:
		print(
			"Economy tick | Sim %.1fh | Extracted %.2f units | Consumed %.2f units | Produced %d batches"
			% [
				simulation_seconds / 3600.0,
				extracted_units,
				consumed_units,
				production_batches
			]
		)

func _process_resource_extraction(
	station: GeneratedStationData,
	simulated_delta: float
) -> float:
	if (
		space_system == null
		or station.station_type == null
		or station.market == null
	):
		return 0.0

	if station.station_type.resource_extraction_rate <= 0.0:
		return 0.0

	var planet: GeneratedPlanetData = space_system.get_planet_by_id(
		station.planet_id
	)
	if planet == null:
		return 0.0

	var simulated_hours: float = simulated_delta / 3600.0
	var extracted_units: float = 0.0

	for resource_data: ResourceData in station.station_type.resource_extraction:
		if resource_data == null:
			continue

		var abundance: float = float(
			planet.resource_abundance.get(resource_data.id, 0.0)
		)
		var extraction_rate: float = (
			station.station_type.resource_extraction_rate
			* clampf(abundance, 0.0, 1.0)
		)
		var extracted_amount: float = extraction_rate * simulated_hours

		if extracted_amount <= 0.0:
			continue

		var current_supply: float = float(
			station.market.supply.get(resource_data.id, 0.0)
		)
		station.market.supply[resource_data.id] = current_supply + extracted_amount
		extracted_units += extracted_amount

	return extracted_units

func _consume_station_demand(
	station: GeneratedStationData,
	simulated_delta: float
) -> float:
	if station.market == null or station.station_type == null:
		return 0.0

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

func _process_station_production(
	station: GeneratedStationData,
	simulated_delta: float
) -> int:
	if station.station_type == null or station.market == null:
		return 0

	var completed_batches: int = 0

	for recipe: ProductionRecipeData in station.station_type.production_recipes:
		if recipe == null or recipe.output == null:
			continue
		if recipe.production_time <= 0.0:
			continue

		var station_progress: Dictionary = production_progress.get(station.id, {}) as Dictionary
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
		production_progress[station.id] = station_progress

	return completed_batches

func _has_recipe_inputs(station: GeneratedStationData, recipe: ProductionRecipeData) -> bool:
	if station.market == null:
		return false

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
	if station.market == null:
		return

	for ingredient: RecipeIngredientData in recipe.inputs:
		if ingredient == null or ingredient.quantity <= 0.0:
			continue

		var item_id: String = _get_ingredient_id(ingredient)
		if item_id.is_empty():
			continue

		var current_supply: float = float(station.market.supply.get(item_id, 0.0))
		station.market.supply[item_id] = maxf(0.0, current_supply - ingredient.quantity)

func _add_recipe_output(station: GeneratedStationData, recipe: ProductionRecipeData) -> void:
	if station.market == null or recipe.output == null:
		return

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
	if station.market == null or station.station_type == null:
		return

	var market: Market = Market.new()

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data == null:
			continue
		_update_price_for_resource(station.market, market, resource_data)

	for resource_data: ResourceData in station.station_type.resource_exports:
		if resource_data == null:
			continue
		_update_price_for_resource(station.market, market, resource_data)

	for good_data: GoodData in station.station_type.good_imports:
		if good_data == null:
			continue
		_update_price_for_good(station.market, market, good_data)

	for good_data: GoodData in station.station_type.good_exports:
		if good_data == null:
			continue
		_update_price_for_good(station.market, market, good_data)

func _update_price_for_resource(market_data: MarketData, market: Market, resource_data: ResourceData) -> void:
	var supply: float = float(market_data.supply.get(resource_data.id, 0.0))
	var demand: float = float(market_data.demand.get(resource_data.id, 0.0))
	var is_producer: bool = _station_exports_resource(station, resource_data.id)
	market_data.current_prices[resource_data.id] = market.calculate_price(
		resource_data.base_value,
		supply,
		demand,
		is_producer
	)

func _update_price_for_good(market_data: MarketData, market: Market, good_data: GoodData) -> void:
	var supply: float = float(market_data.supply.get(good_data.id, 0.0))
	var demand: float = float(market_data.demand.get(good_data.id, 0.0))
	var is_producer: bool = _station_exports_good(station, good_data.id)
	market_data.current_prices[good_data.id] = market.calculate_price(
		good_data.base_value,
		supply,
		demand,
		is_producer
	)


func _station_exports_resource(
	station: GeneratedStationData,
	resource_id: String
) -> bool:
	if station == null or station.station_type == null:
		return false

	for resource_data: ResourceData in station.station_type.resource_exports:
		if resource_data != null and resource_data.id == resource_id:
			return true

	return false

func _station_exports_good(
	station: GeneratedStationData,
	good_id: String
) -> bool:
	if station == null or station.station_type == null:
		return false

	for good_data: GoodData in station.station_type.good_exports:
		if good_data != null and good_data.id == good_id:
			return true

	return false
