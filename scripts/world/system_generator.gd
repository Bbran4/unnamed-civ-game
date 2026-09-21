class_name SystemGenerator
extends RefCounted

var planet_count: int = 5
var station_count: int = 3

const STAR_TYPE_PATHS: Array[String] = [
    "res://data/stars/red_dwarf.tres",
    "res://data/stars/yellow_star.tres",
    "res://data/stars/blue_giant.tres"
]

func generate_system(system_seed: int) -> GeneratedSystemData:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = system_seed

    var generated_system: GeneratedSystemData = GeneratedSystemData.new()
    generated_system.id = "system_%d" % abs(system_seed)
    generated_system.display_name = generate_system_name(rng)
    generated_system.seed_value = system_seed

    var star_types: Array[StarData] = load_star_types()
    if star_types.is_empty():
        push_error("No star types are available.")
        return generated_system

    var star_index: int = rng.randi_range(0, star_types.size() - 1)
    generated_system.star = star_types[star_index]
    generated_system.star_radius = rng.randf_range(
        generated_system.star.min_radius,
        generated_system.star.max_radius
    )
    generated_system.star_mass = rng.randf_range(
        generated_system.star.min_mass,
        generated_system.star.max_mass
    )
    generated_system.star_temperature = rng.randf_range(
        generated_system.star.min_temperature,
        generated_system.star.max_temperature
    )

    var planet_generator: PlanetGenerator = PlanetGenerator.new()

    for planet_index: int in range(planet_count):
        var planet: GeneratedPlanetData = planet_generator.generate_planet(planet_index, rng)
        configure_orbit(planet, planet_index, generated_system.star_mass, rng)
        generated_system.planets.append(planet)

    if generated_system.planets.is_empty():
        push_error("System generation produced no planets.")
        return generated_system

    var planet_indices: Array[int] = []
    for planet_index: int in range(generated_system.planets.size()):
        planet_indices.append(planet_index)

    shuffle_indices(planet_indices, rng)

    var station_generator: StationGenerator = StationGenerator.new()
    var generated_station_count: int = mini(station_count, generated_system.planets.size())
    for station_index: int in range(generated_station_count):
        var planet_index: int = planet_indices[station_index]
        var planet: GeneratedPlanetData = generated_system.planets[planet_index]
        var station: GeneratedStationData = station_generator.generate_station(
            station_index,
            planet,
            rng
        )
        generated_system.stations.append(station)

    return generated_system

func configure_orbit(
    planet: GeneratedPlanetData,
    planet_index: int,
    star_mass: float,
    rng: RandomNumberGenerator
) -> void:
    var orbit_spacing: float = 3200.0
    var orbit_start: float = 2600.0
    planet.orbital_distance = orbit_start + (orbit_spacing * float(planet_index))
    planet.orbital_angle = rng.randf_range(0.0, TAU)

    var safe_star_mass: float = maxf(star_mass, 0.1)
    planet.orbital_period = maxf(
        18.0,
        55.0 * pow(planet.orbital_distance / orbit_start, 1.5) / sqrt(safe_star_mass)
    )

func load_star_types() -> Array[StarData]:
    var star_types: Array[StarData] = []

    for type_path: String in STAR_TYPE_PATHS:
        var loaded_resource: Resource = ResourceLoader.load(type_path)
        var star_type: StarData = loaded_resource as StarData
        if star_type == null:
            push_error("Failed to load star type: %s" % type_path)
            continue

        star_types.append(star_type)

    return star_types

func shuffle_indices(indices: Array[int], rng: RandomNumberGenerator) -> void:
    for index: int in range(indices.size() - 1, 0, -1):
        var swap_index: int = rng.randi_range(0, index)
        var current_value: int = indices[index]
        indices[index] = indices[swap_index]
        indices[swap_index] = current_value

func generate_system_name(rng: RandomNumberGenerator) -> String:
    var names: Array[String] = [
        "Asterion",
        "Caldera",
        "Erebus",
        "Meridian",
        "Nexus",
        "Orpheus",
        "Perseus",
        "Solace"
    ]

    var name_index: int = rng.randi_range(0, names.size() - 1)
    var system_name: String = names[name_index]
    return system_name
