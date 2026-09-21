extends CanvasLayer

const SYSTEM_IDS: Array[String] = [
    "asterion",
    "caldera",
    "nexus"
]

const SYSTEM_NAMES: Array[String] = [
    "Asterion",
    "Caldera",
    "Nexus"
]

const SYSTEM_SCENES: Dictionary = {
    "asterion": "res://scenes/world/systems/asterion.tscn",
    "caldera": "res://scenes/world/systems/caldera.tscn",
    "nexus": "res://scenes/world/systems/nexus.tscn"
}

const MAP_CENTER: Vector2 = Vector2(350.0, 270.0)
const MAP_RADIUS: float = 230.0
const MAX_ORBIT_DISTANCE: float = 15400.0

@onready var panel: Panel = $Panel
@onready var system_name_label: Label = $Panel/SystemName
@onready var star_label: Label = $Panel/MapArea/OrbitMap/StarLabel
@onready var status_label: Label = $Panel/Status
@onready var warp_button: Button = $Panel/WarpButton
@onready var close_button: Button = $Panel/CloseButton
@onready var system_buttons: Array[Button] = [
    $Panel/SystemList/AsterionButton,
    $Panel/SystemList/CalderaButton,
    $Panel/SystemList/NexusButton
]

@onready var orbit_lines: Array[Line2D] = [
    $Panel/MapArea/OrbitMap/Orbit1,
    $Panel/MapArea/OrbitMap/Orbit2,
    $Panel/MapArea/OrbitMap/Orbit3,
    $Panel/MapArea/OrbitMap/Orbit4,
    $Panel/MapArea/OrbitMap/Orbit5
]

@onready var planet_markers: Array[Polygon2D] = [
    $Panel/MapArea/OrbitMap/Planet1,
    $Panel/MapArea/OrbitMap/Planet2,
    $Panel/MapArea/OrbitMap/Planet3,
    $Panel/MapArea/OrbitMap/Planet4,
    $Panel/MapArea/OrbitMap/Planet5
]

@onready var planet_labels: Array[Label] = [
    $Panel/MapArea/OrbitMap/PlanetLabel1,
    $Panel/MapArea/OrbitMap/PlanetLabel2,
    $Panel/MapArea/OrbitMap/PlanetLabel3,
    $Panel/MapArea/OrbitMap/PlanetLabel4,
    $Panel/MapArea/OrbitMap/PlanetLabel5
]

@onready var station_markers: Array[Polygon2D] = [
    $Panel/MapArea/OrbitMap/Station1,
    $Panel/MapArea/OrbitMap/Station2,
    $Panel/MapArea/OrbitMap/Station3
]

@onready var station_labels: Array[Label] = [
    $Panel/MapArea/OrbitMap/StationLabel1,
    $Panel/MapArea/OrbitMap/StationLabel2,
    $Panel/MapArea/OrbitMap/StationLabel3
]

var space_system: SpaceSystem
var map_open: bool = false
var selected_system_id: String = ""

func _ready() -> void:
    space_system = get_parent() as SpaceSystem
    visible = false
    WorldState.map_open = false

    close_button.pressed.connect(close_map)
    warp_button.pressed.connect(_warp_to_selected_system)

    for button_index: int in range(system_buttons.size()):
        var system_id: String = SYSTEM_IDS[button_index]
        system_buttons[button_index].pressed.connect(
            _select_system.bind(system_id)
        )

    _select_system(WorldState.current_system_id)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("open_map"):
        toggle_map()

    if map_open:
        update_map()
        update_warp_state()

func toggle_map() -> void:
    if map_open:
        close_map()
    else:
        open_map()

func open_map() -> void:
    map_open = true
    visible = true
    WorldState.map_open = true
    update_map()
    update_warp_state()

func close_map() -> void:
    map_open = false
    visible = false
    WorldState.map_open = false

func _select_system(system_id: String) -> void:
    selected_system_id = system_id
    update_warp_state()

func update_map() -> void:
    if space_system == null:
        return

    var generated_system: GeneratedSystemData = space_system.generated_system
    system_name_label.text = generated_system.display_name
    star_label.text = generated_system.star.display_name

    for planet_index: int in range(planet_markers.size()):
        var marker: Polygon2D = planet_markers[planet_index]
        var label: Label = planet_labels[planet_index]

        if planet_index >= generated_system.planets.size():
            marker.visible = false
            label.visible = false
            continue

        var planet: GeneratedPlanetData = generated_system.planets[planet_index]
        var position_scale: float = MAP_RADIUS / MAX_ORBIT_DISTANCE
        var map_position: Vector2 = MAP_CENTER + (
            Vector2(cos(
                planet.orbital_angle
                + ((TAU / maxf(planet.orbital_period, 1.0)) * space_system.simulation_time)
            ), sin(
                planet.orbital_angle
                + ((TAU / maxf(planet.orbital_period, 1.0)) * space_system.simulation_time)
            )) * planet.orbital_distance * position_scale
        )

        marker.position = map_position
        marker.visible = true
        label.position = map_position + Vector2(10.0, -10.0)
        label.text = planet.display_name
        label.visible = true

    for station_index: int in range(station_markers.size()):
        var marker: Polygon2D = station_markers[station_index]
        var label: Label = station_labels[station_index]

        if station_index >= generated_system.stations.size():
            marker.visible = false
            label.visible = false
            continue

        var station: GeneratedStationData = generated_system.stations[station_index]
        var station_position: Vector2 = space_system.get_station_position(station.id)
        var map_position: Vector2 = MAP_CENTER + (
            station_position * (MAP_RADIUS / MAX_ORBIT_DISTANCE)
        )

        marker.position = map_position
        marker.visible = true
        label.position = map_position + Vector2(8.0, 8.0)
        label.text = station.display_name
        label.visible = true

func update_warp_state() -> void:
    if space_system == null:
        return

    var current_system_id: String = WorldState.current_system_id
    var is_current_system: bool = selected_system_id == current_system_id
    var is_dangerous: bool = space_system.is_player_in_danger_zone()

    warp_button.disabled = is_current_system or is_dangerous

    if is_current_system:
        status_label.text = "Current system"
    elif is_dangerous:
        status_label.text = "Warp unavailable: hostile activity detected"
    else:
        status_label.text = "Ready to warp to %s" % get_system_name(selected_system_id)

func _warp_to_selected_system() -> void:
    if selected_system_id == WorldState.current_system_id:
        return
    if space_system.is_player_in_danger_zone():
        status_label.text = "Warp unavailable: hostile activity detected"
        return

    var destination_scene: String = SYSTEM_SCENES.get(selected_system_id, "")
    if destination_scene.is_empty():
        status_label.text = "No warp route available."
        return

    WorldState.current_system_id = selected_system_id
    WorldState.current_system_scene = destination_scene
    WorldState.system_entry_position = Vector2(0.0, -1400.0)
    WorldState.map_open = false

    var player_ship: Node2D = get_tree().get_first_node_in_group("player_ship") as Node2D
    if player_ship != null:
        WorldState.station_exit_position = player_ship.global_position

    SceneManager.warp_to_scene(destination_scene)

func get_system_name(system_id: String) -> String:
    var system_index: int = SYSTEM_IDS.find(system_id)
    if system_index < 0:
        return system_id
    return SYSTEM_NAMES[system_index]
