class_name StationGenerator
extends RefCounted

const STATION_TYPE_PATHS: Array[String] = [
    "res://data/economy/stations/mining.tres",
    "res://data/economy/stations/agricultural.tres",
    "res://data/economy/stations/industrial.tres",
    "res://data/economy/stations/refinery.tres",
    "res://data/economy/stations/shipyard.tres",
    "res://data/economy/stations/research.tres",
    "res://data/economy/stations/trade.tres",
    "res://data/economy/stations/military.tres"
]

const FACTION_PATHS: Array[String] = [
    "res://data/factions/colonial_authority.tres",
    "res://data/factions/frontier_coalition.tres",
    "res://data/factions/helios_consortium.tres",
    "res://data/factions/orion_trade_league.tres",
    "res://data/factions/independent.tres"
]

const NAME_PREFIXES: Array[String] = [
    "Gateway",
    "Horizon",
    "Prospect",
    "Meridian",
    "Frontier",
    "Pioneer",
    "Atlas",
    "Wayfarer"
]

const NAME_SUFFIXES: Array[String] = [
    "Station",
    "Port",
    "Terminal",
    "Exchange",
    "Platform",
    "Dock",
    "Outpost",
    "Hub"
]

func generate_station(station_index: int, planet: GeneratedPlanetData, rng: RandomNumberGenerator) -> GeneratedStationData:
    var station_resources: Array = load_station_types()
    var faction_resources: Array = load_factions()

    if station_resources.is_empty() or faction_resources.is_empty():
        push_error("Station generation requires station types and factions.")
        return GeneratedStationData.new()

    var station_type: StationTypeData = choose_station_type(planet, station_resources, rng)
    if station_type == null:
        push_error("No valid station type could be selected.")
        return GeneratedStationData.new()

    var faction: FactionData = choose_faction(station_type, faction_resources, rng)
    if faction == null:
        push_error("No valid faction could be selected.")
        return GeneratedStationData.new()

    var generated_station: GeneratedStationData = GeneratedStationData.new()
    generated_station.id = "station_%d" % station_index
    generated_station.display_name = generate_name(rng)
    generated_station.station_type = station_type
    generated_station.faction = faction
    generated_station.planet_id = planet.id

    var station_population: float = float(planet.population) * station_type.population_multiplier * 0.01
    generated_station.population = maxi(50, int(station_population))

    return generated_station

func choose_station_type(planet: GeneratedPlanetData, station_resources: Array, rng: RandomNumberGenerator) -> StationTypeData:
    var preferred_ids: Array[String] = get_preferred_station_ids(planet.planet_type.id)

    for attempt: int in range(4):
        var candidate_index: int = rng.randi_range(0, station_resources.size() - 1)
        var candidate: StationTypeData = station_resources[candidate_index] as StationTypeData
        if candidate != null and preferred_ids.has(candidate.id):
            return candidate

    var fallback_index: int = rng.randi_range(0, station_resources.size() - 1)
    var fallback_station: StationTypeData = station_resources[fallback_index] as StationTypeData
    return fallback_station

func get_preferred_station_ids(planet_type_id: String) -> Array[String]:
    match planet_type_id:
        "gas_giant":
            return ["refinery", "mining", "trade"]
        "ice_giant":
            return ["refinery", "research", "trade"]
        "volcanic":
            return ["mining", "refinery", "industrial"]
        "frozen":
            return ["mining", "research", "trade"]
        "desert":
            return ["mining", "refinery", "trade"]
        "ocean":
            return ["agricultural", "trade", "research"]
        "habitable":
            return ["agricultural", "industrial", "trade", "research"]
        "barren":
            return ["mining", "industrial", "military"]

    return ["trade"]

func choose_faction(station_type: StationTypeData, faction_resources: Array, rng: RandomNumberGenerator) -> FactionData:
    var compatible_factions: Array[FactionData] = []

    for faction_resource: Resource in faction_resources:
        var faction: FactionData = faction_resource as FactionData
        if faction == null:
            continue

        for preferred_station_resource: Resource in faction.preferred_station_types:
            var preferred_station: StationTypeData = preferred_station_resource as StationTypeData
            if preferred_station != null and preferred_station.id == station_type.id:
                compatible_factions.append(faction)
                break

    if not compatible_factions.is_empty():
        var faction_index: int = rng.randi_range(0, compatible_factions.size() - 1)
        return compatible_factions[faction_index]

    var fallback_index: int = rng.randi_range(0, faction_resources.size() - 1)
    return faction_resources[fallback_index] as FactionData

func load_station_types() -> Array:
    var station_types: Array = []

    for station_path: String in STATION_TYPE_PATHS:
        var loaded_resource: Resource = ResourceLoader.load(station_path)
        if loaded_resource == null:
            push_error("Failed to load station type: %s" % station_path)
            continue

        station_types.append(loaded_resource)

    return station_types

func load_factions() -> Array:
    var factions: Array = []

    for faction_path: String in FACTION_PATHS:
        var loaded_resource: Resource = ResourceLoader.load(faction_path)
        if loaded_resource == null:
            push_error("Failed to load faction: %s" % faction_path)
            continue

        factions.append(loaded_resource)

    return factions

func generate_name(rng: RandomNumberGenerator) -> String:
    var prefix_index: int = rng.randi_range(0, NAME_PREFIXES.size() - 1)
    var suffix_index: int = rng.randi_range(0, NAME_SUFFIXES.size() - 1)
    return "%s %s" % [NAME_PREFIXES[prefix_index], NAME_SUFFIXES[suffix_index]]
