class_name PlanetGenerator
extends RefCounted

const PLANET_TYPE_PATHS: Array[String] = [
    "res://data/planets/barren.tres",
    "res://data/planets/frozen.tres",
    "res://data/planets/habitable.tres",
    "res://data/planets/desert.tres",
    "res://data/planets/ocean.tres",
    "res://data/planets/volcanic.tres",
    "res://data/planets/gas_giant.tres",
    "res://data/planets/ice_giant.tres"
]

const NAME_PREFIXES: Array[String] = [
    "Astra",
    "Vega",
    "Nova",
    "Orion",
    "Helios",
    "Cygnus",
    "Arcturus",
    "Kepler"
]

const NAME_SUFFIXES: Array[String] = [
    "Prime",
    "Major",
    "Minor",
    "Reach",
    "Haven",
    "Frontier",
    "Drift",
    "Deep"
]

func generate_planet(planet_index: int, rng: RandomNumberGenerator) -> GeneratedPlanetData:
    var planet_types: Array[PlanetTypeData] = load_planet_types()
    if planet_types.is_empty():
        push_error("No planet types are available.")
        return GeneratedPlanetData.new()

    var type_index: int = rng.randi_range(0, planet_types.size() - 1)
    var planet_type: PlanetTypeData = planet_types[type_index]

    var generated_planet: GeneratedPlanetData = GeneratedPlanetData.new()
    generated_planet.id = "planet_%d" % planet_index
    generated_planet.display_name = generate_name(rng)
    generated_planet.planet_type = planet_type
    generated_planet.radius = rng.randf_range(planet_type.min_radius, planet_type.max_radius)

    var radius_ratio: float = generated_planet.radius / 5000.0
    generated_planet.gravity = planet_type.gravity_multiplier * radius_ratio
    generated_planet.temperature = rng.randf_range(planet_type.min_temperature, planet_type.max_temperature)

    var population_base: int = calculate_population_base(planet_type)
    generated_planet.population = population_base

    for resource_data: ResourceData in planet_type.available_resources:
        var abundance: float = rng.randf_range(0.35, 1.0)
        generated_planet.resource_abundance[resource_data.id] = abundance

    return generated_planet

func load_planet_types() -> Array[PlanetTypeData]:
    var planet_types: Array[PlanetTypeData] = []

    for type_path: String in PLANET_TYPE_PATHS:
        var loaded_resource: Resource = ResourceLoader.load(type_path)
        var planet_type: PlanetTypeData = loaded_resource as PlanetTypeData
        if planet_type == null:
            push_error("Failed to load planet type: %s" % type_path)
            continue

        planet_types.append(planet_type)

    return planet_types

func calculate_population_base(planet_type: PlanetTypeData) -> int:
    match planet_type.id:
        "habitable":
            return 500000
        "ocean":
            return 250000
        "desert":
            return 100000
        "frozen":
            return 50000
        "barren":
            return 25000
        "volcanic":
            return 10000
        "gas_giant":
            return 5000
        "ice_giant":
            return 5000

    return 1000

func generate_name(rng: RandomNumberGenerator) -> String:
    var prefix_index: int = rng.randi_range(0, NAME_PREFIXES.size() - 1)
    var suffix_index: int = rng.randi_range(0, NAME_SUFFIXES.size() - 1)
    return "%s %s" % [NAME_PREFIXES[prefix_index], NAME_SUFFIXES[suffix_index]]
