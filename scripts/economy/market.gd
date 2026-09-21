class_name Market
extends RefCounted

func build_market(planet: GeneratedPlanetData, station: GeneratedStationData) -> MarketData:
    var market_data: MarketData = MarketData.new()

    for resource_data: ResourceData in station.station_type.resource_imports:
        var abundance: float = float(planet.resource_abundance.get(resource_data.id, 0.0))
        var starting_supply: float = abundance * 100.0
        market_data.supply[resource_data.id] = starting_supply
        market_data.demand[resource_data.id] = calculate_resource_demand(resource_data, station.population)
        market_data.current_prices[resource_data.id] = calculate_price(resource_data.base_value, starting_supply, float(market_data.demand[resource_data.id]))

    for resource_data: ResourceData in station.station_type.resource_exports:
        var abundance: float = float(planet.resource_abundance.get(resource_data.id, 0.0))
        var starting_supply: float = abundance * 500.0
        market_data.supply[resource_data.id] = starting_supply
        market_data.demand[resource_data.id] = calculate_resource_demand(resource_data, station.population)
        market_data.current_prices[resource_data.id] = calculate_price(resource_data.base_value, starting_supply, float(market_data.demand[resource_data.id]))

    for good_data: GoodData in station.station_type.good_imports:
        var starting_supply: float = 50.0
        market_data.supply[good_data.id] = starting_supply
        market_data.demand[good_data.id] = calculate_good_demand(good_data, station.population)
        market_data.current_prices[good_data.id] = calculate_price(good_data.base_value, starting_supply, float(market_data.demand[good_data.id]))

    for good_data: GoodData in station.station_type.good_exports:
        var starting_supply: float = 150.0
        market_data.supply[good_data.id] = starting_supply
        market_data.demand[good_data.id] = calculate_good_demand(good_data, station.population)
        market_data.current_prices[good_data.id] = calculate_price(good_data.base_value, starting_supply, float(market_data.demand[good_data.id]))

    return market_data

func calculate_price(base_value: float, supply: float, demand: float) -> float:
    var safe_supply: float = maxf(supply, 1.0)
    var pressure: float = demand / safe_supply
    var price_multiplier: float = clampf(0.5 + pressure * 0.5, 0.25, 4.0)
    return base_value * price_multiplier

func calculate_resource_demand(resource_data: ResourceData, population: int) -> float:
    var population_factor: float = maxf(float(population) / 10000.0, 1.0)

    match resource_data.category:
        "Biological":
            return population_factor * 20.0
        "Volatile":
            return population_factor * 12.0
        "Metal":
            return population_factor * 10.0
        "Mineral":
            return population_factor * 8.0
        "Rare Mineral":
            return population_factor * 4.0
        "Radioactive":
            return population_factor * 2.0

    return population_factor * 5.0

func calculate_good_demand(good_data: GoodData, population: int) -> float:
    var population_factor: float = maxf(float(population) / 10000.0, 1.0)

    match good_data.category:
        "Consumer":
            return population_factor * 30.0
        "Fuel":
            return population_factor * 25.0
        "Industrial":
            return population_factor * 15.0
        "Agricultural":
            return population_factor * 10.0
        "Medical":
            return population_factor * 6.0
        "Construction":
            return population_factor * 8.0
        "Shipbuilding":
            return population_factor * 5.0
        "Advanced":
            return population_factor * 3.0

    return population_factor * 5.0
