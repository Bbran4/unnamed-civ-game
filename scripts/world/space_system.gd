class_name SpaceSystem
extends Node2D

@export var system_id: String = "asterion"
@export var system_display_name: String = "Asterion"
@export var system_seed: int = 18472931
@export var planet_count: int = 5
@export var station_count: int = 3
@export var system_scene_path: String = "res://scenes/world/systems/asterion.tscn"
@export var orbit_time_scale: float = 0.05

const PLANET_SCENE: PackedScene = preload("res://scenes/planets/first_planet.tscn")
const MOON_SCENE: PackedScene = preload("res://scenes/planets/moon.tscn")
const STATION_SCENE: PackedScene = preload("res://scenes/stations/first_space_station.tscn")
const ASTEROID_FIELD_SCENE: PackedScene = preload("res://scenes/world/asteroid_field.tscn")

@onready var generated_objects: Node2D = $GeneratedObjects
@onready var orbit_lines: Node2D = $OrbitLines
@onready var star_visual: GeneratedStarVisual = $Star

var generated_system: GeneratedSystemData = GeneratedSystemData.new()
var simulation_time: float = 0.0
var planet_instances: Dictionary = {}
var moon_instances: Dictionary = {}
var station_instances: Dictionary = {}
var asteroid_fields: Array[AsteroidField] = []

func _ready() -> void:
    add_to_group("space_system")
    WorldState.current_system_id = system_id
    WorldState.current_system_scene = system_scene_path
    generate_and_build_system()

func _process(delta: float) -> void:
    simulation_time += delta * orbit_time_scale
    update_orbits()

func generate_and_build_system() -> void:
    var generator: SystemGenerator = SystemGenerator.new()
    generator.planet_count = planet_count
    generator.station_count = station_count

    generated_system = generator.generate_system(system_seed)
    if not system_display_name.is_empty():
        generated_system.display_name = system_display_name

    clear_generated_objects()
    planet_instances.clear()
    moon_instances.clear()
    station_instances.clear()
    asteroid_fields.clear()
    build_star()
    build_system_visuals()
    build_orbit_lines()
    build_asteroid_fields()
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

        for moon: GeneratedMoonData in planet.moons:
            var moon_instance: Node2D = MOON_SCENE.instantiate() as Node2D
            if moon_instance == null:
                push_error("Moon scene root must inherit Node2D.")
                continue

            planet_instance.add_child(moon_instance)
            moon_instance.name = moon.id

            var moon_visual: GeneratedMoonVisual = moon_instance as GeneratedMoonVisual
            if moon_visual != null:
                moon_visual.apply_data(moon)

            moon_instances[moon.id] = moon_instance

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

func build_asteroid_fields() -> void:
    var belt_distances: Array[Vector2] = [
        Vector2(17000.0, 19500.0),
        Vector2(37000.0, 39500.0)
    ]

    for belt_index: int in range(belt_distances.size()):
        var belt: AsteroidField = ASTEROID_FIELD_SCENE.instantiate() as AsteroidField
        if belt == null:
            push_error("Asteroid field scene root must use AsteroidField.")
            continue

        belt.inner_radius = belt_distances[belt_index].x
        belt.outer_radius = belt_distances[belt_index].y
        belt.asteroid_count = 90
        belt.random_seed = system_seed + (belt_index * 7919)
        belt.orbital_period = 150.0 + float(belt_index * 35)

        generated_objects.add_child(belt)
        asteroid_fields.append(belt)

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

        var planet_angle: float = get_orbit_angle(
            planet.orbital_angle,
            planet.orbital_period
        )
        var planet_position: Vector2 = Vector2(cos(planet_angle), sin(planet_angle)) * planet.orbital_distance
        planet_instance.position = planet_position

        update_moons_for_planet(planet, planet_position, planet_angle)
        update_stations_for_planet(planet, planet_position)

func update_moons_for_planet(
    planet: GeneratedPlanetData,
    _planet_position: Vector2,
    _planet_angle: float
) -> void:
    for moon: GeneratedMoonData in planet.moons:
        var moon_instance: Node2D = moon_instances.get(moon.id) as Node2D
        if moon_instance == null:
            continue

        var moon_angle: float = get_orbit_angle(
            moon.orbital_angle,
            moon.orbital_period
        )
        moon_instance.position = Vector2(cos(moon_angle), sin(moon_angle)) * moon.orbital_distance

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

        var station_angle: float = get_orbit_angle(
            station.orbital_angle,
            station.orbital_period
        )
        var station_offset: Vector2 = Vector2(cos(station_angle), sin(station_angle)) * station.orbital_distance
        station_instance.position = planet_position + station_offset

func get_orbit_angle(initial_angle: float, period: float) -> float:
    var orbital_speed: float = TAU / maxf(period, 1.0)
    return initial_angle + (orbital_speed * simulation_time)

func get_planet_position_by_id(planet_id: String) -> Vector2:
    var planet: GeneratedPlanetData = get_planet_by_id(planet_id)
    if planet == null:
        return Vector2.ZERO

    var angle: float = get_orbit_angle(
        planet.orbital_angle,
        planet.orbital_period
    )
    return Vector2(cos(angle), sin(angle)) * planet.orbital_distance

func get_planet_velocity_by_id(planet_id: String) -> Vector2:
    var planet: GeneratedPlanetData = get_planet_by_id(planet_id)
    if planet == null:
        return Vector2.ZERO

    var orbital_speed: float = (TAU / maxf(planet.orbital_period, 1.0)) * orbit_time_scale
    var angle: float = get_orbit_angle(
        planet.orbital_angle,
        planet.orbital_period
    )
    return Vector2(-sin(angle), cos(angle)) * planet.orbital_distance * orbital_speed

func get_planet_by_id(planet_id: String) -> GeneratedPlanetData:
    for planet: GeneratedPlanetData in generated_system.planets:
        if planet.id == planet_id:
            return planet

    return null

func get_station_position(station_id: String) -> Vector2:
    for station: GeneratedStationData in generated_system.stations:
        if station.id != station_id:
            continue

        var planet_position: Vector2 = get_planet_position_by_id(station.planet_id)
        var station_angle: float = get_orbit_angle(
            station.orbital_angle,
            station.orbital_period
        )
        var station_offset: Vector2 = Vector2(cos(station_angle), sin(station_angle)) * station.orbital_distance
        return planet_position + station_offset

    return Vector2.ZERO

func get_station_velocity(station: GeneratedStationData) -> Vector2:
    var planet_velocity: Vector2 = get_planet_velocity_by_id(station.planet_id)
    var orbital_speed: float = (TAU / maxf(station.orbital_period, 1.0)) * orbit_time_scale
    var station_angle: float = get_orbit_angle(
        station.orbital_angle,
        station.orbital_period
    )
    var local_velocity: Vector2 = Vector2(-sin(station_angle), cos(station_angle)) * station.orbital_distance * orbital_speed
    return planet_velocity + local_velocity

func get_reference_velocity_at_position(world_position: Vector2) -> Vector2:
    var nearest_station_distance: float = INF
    var nearest_station_velocity: Vector2 = Vector2.ZERO

    for station: GeneratedStationData in generated_system.stations:
        var station_position: Vector2 = get_station_position(station.id)
        var station_distance: float = world_position.distance_to(station_position)
        if station_distance < nearest_station_distance:
            nearest_station_distance = station_distance
            nearest_station_velocity = get_station_velocity(station)

    if nearest_station_distance <= 2500.0:
        return nearest_station_velocity

    var nearest_planet_distance: float = INF
    var nearest_planet_velocity: Vector2 = Vector2.ZERO

    for planet: GeneratedPlanetData in generated_system.planets:
        var planet_position: Vector2 = get_planet_position_by_id(planet.id)
        var planet_distance: float = world_position.distance_to(planet_position)
        var planet_visual_radius: float = get_planet_visual_radius(planet.radius)
        var influence_radius: float = maxf(3000.0, planet_visual_radius * 12.0)

        if planet_distance <= influence_radius and planet_distance < nearest_planet_distance:
            nearest_planet_distance = planet_distance
            nearest_planet_velocity = get_planet_velocity_by_id(planet.id)

    return nearest_planet_velocity

func get_planet_visual_radius(planet_radius: float) -> float:
    var clamped_radius: float = clampf(planet_radius, 2500.0, 80000.0)
    var base_visual_radius: float = remap(
        clamped_radius,
        2500.0,
        80000.0,
        80.0,
        600.0
    )
    return base_visual_radius * 2.0

func is_player_in_danger_zone() -> bool:
    var player_ship: Node = get_tree().get_first_node_in_group("player_ship")
    if player_ship == null:
        return true

    if not player_ship.has_method("is_in_danger_zone"):
        return true

    var danger_result: Variant = player_ship.call("is_in_danger_zone")
    return bool(danger_result)

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
            "  Planet %s | Type: %s | Radius: %.0f | Orbit: %.0f | Period: %.1fs | Gravity: %.2f | Mass: %.2f | Moons: %d | Temp: %.0f K | Population: %d"
            % [
                planet.display_name,
                planet.planet_type.display_name,
                planet.radius,
                planet.orbital_distance,
                planet.orbital_period,
                planet.gravity,
                planet.mass,
                planet.moons.size(),
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
            "  Station %s | Type: %s | Faction: %s | Planet: %s | Orbit: %.0f | Period: %.1fs | Population: %d"
            % [
                station.display_name,
                station.station_type.display_name,
                station.faction.display_name,
                station.planet_id,
                station.orbital_distance,
                station.orbital_period,
                station.population
            ]
        )
