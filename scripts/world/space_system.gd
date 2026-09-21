class_name SpaceSystem
extends Node2D

@export var system_seed: int = 18472931
@export var planet_count: int = 5
@export var station_count: int = 3
@export var system_scene_path: String = "res://scenes/world/systems/asterion.tscn"

const PLANET_SCENE: PackedScene = preload("res://scenes/planets/first_planet.tscn")
const STATION_SCENE: PackedScene = preload("res://scenes/stations/first_space_station.tscn")
const STATION_DISTANCE_FROM_PLANET: float = 500.0

@onready var generated_objects: Node2D = $GeneratedObjects
@onready var orbit_lines: Node2D = $OrbitLines
@onready var star_visual: GeneratedStarVisual = $Star

var generated_system: GeneratedSystemData = GeneratedSystemData.new()
var simulation_time: float = 0.0
var planet_instances: Dictionary = {}
var station_instances: Dictionary = {}

func _ready() -> void:
    add_to_group("space_system")
    generate_and_build_system()

func _process(delta: float) -> void:
    simulation_time += delta
    update_orbits()

func generate_and_build_system() -> void:
    var generator: SystemGenerator = SystemGenerator.new()
    generator.planet_count = planet_count
    generator.station_count = station_count

    generated_system = generator.generate_system(system_seed)
    clear_generated_objects()
    planet_instances.clear()
    station_instances.clear()
    build_star()
    build_system_visuals()
    build_orbit_lines()
    print_system_summary()

func clear_generated_objects() -> void:
    for child: Node in generated_objects.get_children():
        child.queue_free()

func build_star() -> void:
    if generated_system.star == null:
        return

    star_visual.apply_data(
        generated_system.star,
        generated_system.star_radius
    )

func build_system_visuals() -> void:
    for planet_index: int in range(generated_system.planets.size()):
        var planet: GeneratedPlanetData = generated_system.planets[planet_index]
        var planet_instance: Node2D = PLANET_SCENE.instantiate() as Node2D
        if planet_instance == null:
            push_error("Planet scene root must inherit Node2D.")
            continue

        generated_objects.add_child(planet_instance)
        planet_instance.name = planet.id

        var planet_visual: GeneratedPlanetVisual = planet_instance as GeneratedPlanetVisual
        if planet_visual != null:
            planet_visual.apply_data(planet)

        planet_instances[planet.id] = planet_instance

    for station_index: int in range(generated_system.stations.size()):
        var station: GeneratedStationData = generated_system.stations[station_index]
        var station_instance: Node2D = STATION_SCENE.instantiate() as Node2D
        if station_instance == null:
            push_error("Station scene root must inherit Node2D.")
            continue

        generated_objects.add_child(station_instance)
        station_instance.name = station.id

        var station_label: Label = station_instance.get_node("StationLabel") as Label
        if station_label != null:
            station_label.text = "%s\n%s\n%s" % [
                station.display_name,
                station.station_type.display_name,
                station.faction.display_name
            ]

        station_instances[station.id] = station_instance

func build_orbit_lines() -> void:
    for orbit_index: int in range(generated_system.planets.size()):
        var line: Line2D = orbit_lines.get_node_or_null(
            "Orbit%d" % (orbit_index + 1)
        ) as Line2D
        if line == null:
            continue

        var planet: GeneratedPlanetData = generated_system.planets[orbit_index]
        line.points = build_circle_points(planet.orbital_distance)

func build_circle_points(radius: float) -> PackedVector2Array:
    var points: PackedVector2Array = PackedVector2Array()
    var point_count: int = 96

    for point_index: int in range(point_count + 1):
        var angle: float = TAU * float(point_index) / float(point_count)
        points.append(Vector2(cos(angle), sin(angle)) * radius)

    return points

func update_orbits() -> void:
    for planet: GeneratedPlanetData in generated_system.planets:
        var planet_instance: Node2D = planet_instances.get(planet.id) as Node2D
        if planet_instance == null:
            continue

        var orbital_speed: float = TAU / maxf(planet.orbital_period, 1.0)
        var angle: float = planet.orbital_angle + (orbital_speed * simulation_time)
        var planet_position: Vector2 = Vector2(cos(angle), sin(angle)) * planet.orbital_distance
        planet_instance.position = planet_position

        update_stations_for_planet(planet, planet_position)

func update_stations_for_planet(
    planet: GeneratedPlanetData,
    planet_position: Vector2
) -> void:
    for station: GeneratedStationData in generated_system.stations:
        if station.planet_id != planet.id:
            continue

        var station_instance: Node2D = station_instances.get(station.id) as Node2D
        if station_instance == null:
            continue

        station_instance.position = planet_position + get_station_offset(planet)

func get_planet_position_by_id(planet_id: String) -> Vector2:
    var planet: GeneratedPlanetData = get_planet_by_id(planet_id)
    if planet == null:
        return Vector2.ZERO

    var orbital_speed: float = TAU / maxf(planet.orbital_period, 1.0)
    var angle: float = planet.orbital_angle + (orbital_speed * simulation_time)
    return Vector2(cos(angle), sin(angle)) * planet.orbital_distance

func get_planet_by_id(planet_id: String) -> GeneratedPlanetData:
    for planet: GeneratedPlanetData in generated_system.planets:
        if planet.id == planet_id:
            return planet

    return null

func get_station_offset(planet: GeneratedPlanetData) -> Vector2:
    if planet == null:
        return Vector2(STATION_DISTANCE_FROM_PLANET, 0.0)

    var visual_helper: GeneratedPlanetVisual = GeneratedPlanetVisual.new()
    var visual_radius: float = visual_helper.get_visual_radius(planet.radius)
    var station_distance: float = visual_radius + STATION_DISTANCE_FROM_PLANET
    return Vector2(station_distance, 0.0)

func get_station_position(station_id: String) -> Vector2:
    for station: GeneratedStationData in generated_system.stations:
        if station.id != station_id:
            continue

        var planet_position: Vector2 = get_planet_position_by_id(station.planet_id)
        var planet: GeneratedPlanetData = get_planet_by_id(station.planet_id)
        return planet_position + get_station_offset(planet)

    return Vector2.ZERO

func print_system_summary() -> void:
    print("Generated system: %s" % generated_system.display_name)
    print("Seed: %d" % generated_system.seed_value)
    print("Star: %s | Radius: %.0f | Mass: %.2f | Temperature: %.0f K" % [
        generated_system.star.display_name,
        generated_system.star_radius,
        generated_system.star_mass,
        generated_system.star_temperature
    ])
    print("Planets: %d" % generated_system.planets.size())

    for planet: GeneratedPlanetData in generated_system.planets:
        print(
            "  Planet %s | Type: %s | Radius: %.0f | Orbit: %.0f | Period: %.1fs | Gravity: %.2f | Temp: %.0f K | Population: %d"
            % [
                planet.display_name,
                planet.planet_type.display_name,
                planet.radius,
                planet.orbital_distance,
                planet.orbital_period,
                planet.gravity,
                planet.temperature,
                planet.population
            ]
        )

        var resource_summary: Array[String] = []
        for resource_id: String in planet.resource_abundance:
            var abundance: float = float(planet.resource_abundance[resource_id])
            resource_summary.append("%s %.0f%%" % [resource_id, abundance * 100.0])
        print("    Resources: %s" % ", ".join(resource_summary))

    print("Stations: %d" % generated_system.stations.size())

    for station: GeneratedStationData in generated_system.stations:
        print(
            "  Station %s | Type: %s | Faction: %s | Planet: %s | Population: %d"
            % [
                station.display_name,
                station.station_type.display_name,
                station.faction.display_name,
                station.planet_id,
                station.population
            ]
        )
