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
        configure_moons(planet, planet_index, generated_system.star_mass, rng)
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
    var orbit_spacing: float = 10000.0
    var orbit_start: float = 12000.0
    planet.orbital_distance = orbit_start + (orbit_spacing * float(planet_index))
    planet.orbital_angle = rng.randf_range(0.0, TAU)

    var safe_star_mass: float = maxf(star_mass, 0.1)
    planet.orbital_period = maxf(
        18.0,
        80.0 * pow(planet.orbital_distance / orbit_start, 1.5) / sqrt(safe_star_mass)
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

func configure_moons(
    planet: GeneratedPlanetData,
    planet_index: int,
    star_mass: float,
    rng: RandomNumberGenerator
) -> void:
    var moon_count: int = get_moon_count(planet.planet_type.id, rng)

    for moon_index: int in range(moon_count):
        var moon: GeneratedMoonData = GeneratedMoonData.new()
        moon.id = "%s_moon_%d" % [planet.id, moon_index]
        moon.display_name = "%s %s" % [planet.display_name, roman_numeral(moon_index + 1)]

        var moon_radius: float = rng.randf_range(500.0, 9000.0)
        moon.radius = moon_radius

        var moon_mass_scale: float = pow(moon_radius / 5000.0, 3.0)
        moon.mass = maxf(0.0001, moon_mass_scale * rng.randf_range(0.001, 0.01))

        var minimum_distance: float = maxf(planet.radius * 3.0, 1800.0)
        var maximum_distance: float = maxf(minimum_distance + 1000.0, planet.radius * 9.0)
        moon.orbital_distance = rng.randf_range(minimum_distance, maximum_distance)
        moon.orbital_angle = rng.randf_range(0.0, TAU)

        var safe_planet_mass: float = maxf(planet.mass, 0.01)
        moon.orbital_period = maxf(
            8.0,
            16.0 * pow(moon.orbital_distance / minimum_distance, 1.5) / sqrt(safe_planet_mass)
        )

        planet.moons.append(moon)

func get_moon_count(planet_type_id: String, rng: RandomNumberGenerator) -> int:
    match planet_type_id:
        "gas_giant":
            return rng.randi_range(2, 5)
        "ice_giant":
            return rng.randi_range(1, 4)
        "ocean":
            return rng.randi_range(0, 2)
        "habitable":
            return rng.randi_range(0, 2)
        "desert":
            return rng.randi_range(0, 2)
        "frozen":
            return rng.randi_range(0, 3)
        "volcanic":
            return rng.randi_range(0, 2)
        "barren":
            return rng.randi_range(0, 1)

    return 0

func roman_numeral(value: int) -> String:
    match value:
        1:
            return "I"
        2:
            return "II"
        3:
            return "III"
        4:
            return "IV"
        5:
            return "V"

    return str(value)
