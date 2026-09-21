class_name SpaceSystem
extends Node2D

@export var system_seed: int = 18472931
@export var planet_count: int = 5
@export var station_count: int = 3

const PLANET_SCENE: PackedScene = preload("res://scenes/planets/first_planet.tscn")
const STATION_SCENE: PackedScene = preload("res://scenes/stations/first_space_station.tscn")

@onready var generated_objects: Node2D = $GeneratedObjects

var generated_system: GeneratedSystemData = GeneratedSystemData.new()

func _ready() -> void:
    generate_and_build_system()

func generate_and_build_system() -> void:
    var generator: SystemGenerator = SystemGenerator.new()
    generator.planet_count = planet_count
    generator.station_count = station_count

    generated_system = generator.generate_system(system_seed)
    clear_generated_objects()
    build_system_visuals()
    print_system_summary()

func clear_generated_objects() -> void:
    for child: Node in generated_objects.get_children():
        child.queue_free()

func build_system_visuals() -> void:
    var planet_positions: Dictionary = {}

    for planet_index: int in range(generated_system.planets.size()):
        var planet: GeneratedPlanetData = generated_system.planets[planet_index]
        var planet_instance: Node2D = PLANET_SCENE.instantiate() as Node2D
        if planet_instance == null:
            push_error("Planet scene root must inherit Node2D.")
            continue

        generated_objects.add_child(planet_instance)
        planet_instance.name = planet.id
        planet_instance.position = get_planet_position(planet_index, generated_system.planets.size())
        planet_positions[planet.id] = planet_instance.position

        var planet_visual: GeneratedPlanetVisual = planet_instance as GeneratedPlanetVisual
        if planet_visual != null:
            planet_visual.apply_data(planet)

    for station_index: int in range(generated_system.stations.size()):
        var station: GeneratedStationData = generated_system.stations[station_index]
        var station_instance: Node2D = STATION_SCENE.instantiate() as Node2D
        if station_instance == null:
            push_error("Station scene root must inherit Node2D.")
            continue

        generated_objects.add_child(station_instance)
        station_instance.name = station.id

        var planet_position: Vector2 = planet_positions.get(station.planet_id, Vector2.ZERO)
        station_instance.position = planet_position + get_station_offset(station_index)

        var station_label: Label = station_instance.get_node("StationLabel") as Label
        if station_label != null:
            station_label.text = "%s\n%s\n%s" % [
                station.display_name,
                station.station_type.display_name,
                station.faction.display_name
            ]

func get_planet_position(planet_index: int, total_planets: int) -> Vector2:
    if total_planets <= 0:
        return Vector2.ZERO

    var angle: float = -PI * 0.5 + (TAU * float(planet_index) / float(total_planets))
    var orbit_radius: float = 300.0 + (220.0 * float(planet_index))
    return Vector2(cos(angle), sin(angle)) * orbit_radius

func get_station_offset(station_index: int) -> Vector2:
    var angle: float = float(station_index) * TAU / maxf(float(station_count), 1.0)
    return Vector2(cos(angle), sin(angle)) * 250.0

func print_system_summary() -> void:
    print("Generated system: %s" % generated_system.display_name)
    print("Seed: %d" % generated_system.seed_value)
    print("Planets: %d" % generated_system.planets.size())

    for planet: GeneratedPlanetData in generated_system.planets:
        print(
            "  Planet %s | Type: %s | Radius: %.0f | Gravity: %.2f | Temp: %.0f K | Population: %d"
            % [
                planet.display_name,
                planet.planet_type.display_name,
                planet.radius,
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
