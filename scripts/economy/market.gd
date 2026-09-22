class_name Market
extends RefCounted

const RESOURCE_PATHS: Array[String] = [
	"res://data/economy/resources/carbon.tres",
	"res://data/economy/resources/copper.tres",
	"res://data/economy/resources/crystals.tres",
	"res://data/economy/resources/helium.tres",
	"res://data/economy/resources/hydrogen.tres",
	"res://data/economy/resources/iron.tres",
	"res://data/economy/resources/organic_matter.tres",
	"res://data/economy/resources/rare_earths.tres",
	"res://data/economy/resources/silicates.tres",
	"res://data/economy/resources/titanium.tres",
	"res://data/economy/resources/uranium.tres",
	"res://data/economy/resources/water.tres"
]

const GOOD_PATHS: Array[String] = [
	"res://data/economy/goods/advanced_components.tres",
	"res://data/economy/goods/construction_materials.tres",
	"res://data/economy/goods/electronics.tres",
	"res://data/economy/goods/fertilizer.tres",
	"res://data/economy/goods/food.tres",
	"res://data/economy/goods/fuel.tres",
	"res://data/economy/goods/machinery.tres",
	"res://data/economy/goods/medical_supplies.tres",
	"res://data/economy/goods/ship_components.tres",
	"res://data/economy/goods/steel.tres"
]

const INITIAL_STOCK_SECONDS: float = 60.0
const PRICE_TARGET_SECONDS: float = 600.0

func build_market(planet: GeneratedPlanetData, station: GeneratedStationData) -> MarketData:
	var market_data: MarketData = MarketData.new()
	var resources: Array[ResourceData] = _load_resources()
	var goods: Array[GoodData] = _load_goods()

	for resource_data: ResourceData in resources:
		if resource_data == null:
			continue
		_register_item(market_data, resource_data.id, resource_data.base_value)

	for good_data: GoodData in goods:
		if good_data == null:
			continue
		_register_item(market_data, good_data.id, good_data.base_value)

	_initialize_extraction_supply(market_data, planet, station)
	_initialize_operational_demand(market_data, station)
	_initialize_production_demand(market_data, station)

	for item_id: String in market_data.supply.keys():
		var base_value: float = float(market_data.base_values.get(item_id, 1.0))
		var supply: float = float(market_data.supply[item_id])
		var demand: float = float(market_data.demand[item_id])
		market_data.current_prices[item_id] = calculate_price(base_value, supply, demand)

	return market_data

func calculate_price(
	base_value: float,
	supply: float,
	demand_per_second: float
) -> float:
	var safe_base_value: float = maxf(base_value, 0.01)
	var target_stock: float = maxf(demand_per_second * PRICE_TARGET_SECONDS, 1.0)
	var safe_supply: float = maxf(supply, 0.01)
	var pressure: float = target_stock / safe_supply
	var price_multiplier: float = clampf(0.5 + (pressure * 0.5), 0.25, 4.0)
	return safe_base_value * price_multiplier

func _register_item(
	market_data: MarketData,
	item_id: String,
	base_value: float
) -> void:
	if item_id.is_empty():
		return

	market_data.supply[item_id] = 0.0
	market_data.demand[item_id] = 0.0
	market_data.operational_demand[item_id] = 0.0
	market_data.base_values[item_id] = base_value
	market_data.current_prices[item_id] = base_value

func _initialize_extraction_supply(
	market_data: MarketData,
	planet: GeneratedPlanetData,
	station: GeneratedStationData
) -> void:
	if station == null or station.station_type == null or planet == null:
		return

	for resource_data: ResourceData in station.station_type.resource_extraction:
		if resource_data == null:
			continue

		var abundance: float = clampf(
			float(planet.resource_abundance.get(resource_data.id, 0.0)),
			0.0,
			1.0
		)
		var extraction_rate: float = station.station_type.resource_extraction_rate * abundance
		var starting_supply: float = extraction_rate * INITIAL_STOCK_SECONDS

		market_data.supply[resource_data.id] = starting_supply

func _initialize_operational_demand(
	market_data: MarketData,
	station: GeneratedStationData
) -> void:
	if station == null or station.station_type == null:
		return

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data == null:
			continue

		var demand_rate: float = calculate_operational_demand(
			resource_data.category,
			station.population
		)
		market_data.operational_demand[resource_data.id] = (
			float(market_data.operational_demand.get(resource_data.id, 0.0))
			+ demand_rate
		)
		market_data.demand[resource_data.id] = (
			float(market_data.demand.get(resource_data.id, 0.0))
			+ demand_rate
		)

	for good_data: GoodData in station.station_type.good_imports:
		if good_data == null:
			continue

		var demand_rate: float = calculate_operational_demand(
			good_data.category,
			station.population
		)
		market_data.operational_demand[good_data.id] = (
			float(market_data.operational_demand.get(good_data.id, 0.0))
			+ demand_rate
		)
		market_data.demand[good_data.id] = (
			float(market_data.demand.get(good_data.id, 0.0))
			+ demand_rate
		)

func _initialize_production_demand(
	market_data: MarketData,
	station: GeneratedStationData
) -> void:
	if station == null or station.station_type == null:
		return

	for recipe: ProductionRecipeData in station.station_type.production_recipes:
		if recipe == null or recipe.production_time <= 0.0:
			continue

		for ingredient: RecipeIngredientData in recipe.inputs:
			if ingredient == null or ingredient.quantity <= 0.0:
				continue

			var item_id: String = _get_ingredient_id(ingredient)
			if item_id.is_empty():
				continue

			var demand_rate: float = ingredient.quantity / recipe.production_time
			market_data.demand[item_id] = (
				float(market_data.demand.get(item_id, 0.0))
				+ demand_rate
			)

func _refresh_demands(market_data: MarketData) -> void:
\tfor item_id: String in market_data.supply.keys():
\t\tvar supply: float = float(market_data.supply.get(item_id, 0.0))
\t\tvar demand_rate: float = float(market_data.demand_rate.get(item_id, 0.0))
\t\tvar target_stock: float = maxf(demand_rate * PRICE_TARGET_SECONDS, 1.0)
\t\tmarket_data.demand[item_id] = maxf(target_stock - supply, 0.0)

func calculate_operational_demand(
	category: String,
	population: int
) -> float:
	var population_factor: float = maxf(float(population) / 10000.0, 0.1)

	match category:
		"Biological", "Agricultural", "Consumer":
			return population_factor * 0.020
		"Volatile", "Fuel":
			return population_factor * 0.010
		"Metal", "Mineral", "Industrial", "Construction":
			return population_factor * 0.004
		"Rare Mineral", "Advanced", "Shipbuilding":
			return population_factor * 0.001
		"Radioactive":
			return population_factor * 0.0005
		"Medical":
			return population_factor * 0.002

	return population_factor * 0.002

func _get_ingredient_id(ingredient: RecipeIngredientData) -> String:
	if ingredient.resource != null:
		return ingredient.resource.id
	if ingredient.good != null:
		return ingredient.good.id
	return ""

func _load_resources() -> Array[ResourceData]:
	var resources: Array[ResourceData] = []

	for resource_path: String in RESOURCE_PATHS:
		var loaded_resource: Resource = ResourceLoader.load(resource_path)
		var resource_data: ResourceData = loaded_resource as ResourceData
		if resource_data != null:
			resources.append(resource_data)

	return resources

func _load_goods() -> Array[GoodData]:
	var goods: Array[GoodData] = []

	for good_path: String in GOOD_PATHS:
		var loaded_resource: Resource = ResourceLoader.load(good_path)
		var good_data: GoodData = loaded_resource as GoodData
		if good_data != null:
			goods.append(good_data)

	return goods
