class_name SystemGenerator
extends RefCounted

var planet_count: int = 5
var station_count: int = 3

func generate_system(system_seed: int) -> GeneratedSystemData:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = system_seed

    var generated_system: GeneratedSystemData = GeneratedSystemData.new()
    generated_system.id = "system_%d" % abs(system_seed)
    generated_system.display_name = generate_system_name(rng)
    generated_system.seed_value = system_seed

    var planet_generator: PlanetGenerator = PlanetGenerator.new()
    var station_generator: StationGenerator = StationGenerator.new()

    for planet_index: int in range(planet_count):
        var planet: GeneratedPlanetData = planet_generator.generate_planet(planet_index, rng)
        generated_system.planets.append(planet)

    if generated_system.planets.is_empty():
        push_error("System generation produced no planets.")
        return generated_system

    for station_index: int in range(mini(station_count, generated_system.planets.size())):
        var planet_index: int = rng.randi_range(0, generated_system.planets.size() - 1)
        var planet: GeneratedPlanetData = generated_system.planets[planet_index]
        var station: GeneratedStationData = station_generator.generate_station(station_index, planet, rng)
        generated_system.stations.append(station)

    return generated_system

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
