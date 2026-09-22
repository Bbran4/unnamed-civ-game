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
const MIN_MAP_ZOOM: float = 0.5
const MAX_MAP_ZOOM: float = 3.0
const MAP_ZOOM_STEP: float = 0.15
const TRAFFIC_REFRESH_INTERVAL: float = 0.05

@onready var panel: Panel = $Panel
@onready var system_name_label: Label = $Panel/SystemName
@onready var star_label: Label = $Panel/MapArea/OrbitMap/StarLabel
@onready var player_marker: Polygon2D = $Panel/MapArea/OrbitMap/PlayerMarker
@onready var player_label: Label = $Panel/MapArea/OrbitMap/PlayerLabel
@onready var status_label: Label = $Panel/Status
@onready var warp_button: Button = $Panel/WarpButton
@onready var hyperdrive_button: Button = $Panel/HyperdriveButton
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

@onready var station_buttons: Array[Button] = [
    $Panel/StationList/Station1Button,
    $Panel/StationList/Station2Button,
    $Panel/StationList/Station3Button
]

@onready var station_labels: Array[Label] = [
    $Panel/MapArea/OrbitMap/StationLabel1,
    $Panel/MapArea/OrbitMap/StationLabel2,
    $Panel/MapArea/OrbitMap/StationLabel3
]

@onready var civilian_markers: Array[Polygon2D] = [
    $Panel/MapArea/OrbitMap/Civilian1,
    $Panel/MapArea/OrbitMap/Civilian2,
    $Panel/MapArea/OrbitMap/Civilian3,
    $Panel/MapArea/OrbitMap/Civilian4
]

@onready var freighter_markers: Array[Polygon2D] = [
    $Panel/MapArea/OrbitMap/Freighter1,
    $Panel/MapArea/OrbitMap/Freighter2
]

var space_system: SpaceSystem
var map_open: bool = false
var selected_system_id: String = ""
var selected_station_id: String = ""
var map_zoom: float = 1.0
var traffic_refresh_timer: float = 0.0

func _ready() -> void:
    space_system = get_parent() as SpaceSystem
    visible = false
    WorldState.map_open = false

    close_button.pressed.connect(close_map)
    panel.gui_input.connect(_on_map_gui_input)
    warp_button.pressed.connect(_warp_to_selected_system)
    hyperdrive_button.pressed.connect(_hyperdrive_to_selected_station)

    for station_button_index: int in range(station_buttons.size()):
        station_buttons[station_button_index].pressed.connect(
            _select_station.bind(station_button_index)
        )

    for button_index: int in range(system_buttons.size()):
        var system_id: String = SYSTEM_IDS[button_index]
        system_buttons[button_index].pressed.connect(
            _select_system.bind(system_id)
        )

    _select_system(WorldState.current_system_id)

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("open_map"):
        toggle_map()

    if map_open:
        traffic_refresh_timer = maxf(0.0, traffic_refresh_timer - delta)
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

    for orbit_index: int in range(orbit_lines.size()):
        var orbit_line: Line2D = orbit_lines[orbit_index]

        if orbit_index >= generated_system.planets.size():
            orbit_line.visible = false
            continue

        var orbit_planet: GeneratedPlanetData = generated_system.planets[orbit_index]
        orbit_line.points = build_map_circle_points(orbit_planet.orbital_distance)
        orbit_line.position = MAP_CENTER
        orbit_line.visible = true

    for planet_index: int in range(planet_markers.size()):
        var marker: Polygon2D = planet_markers[planet_index]
        var label: Label = planet_labels[planet_index]

        if planet_index >= generated_system.planets.size():
            marker.visible = false
            label.visible = false
            continue

        var planet: GeneratedPlanetData = generated_system.planets[planet_index]
        var position_scale: float = MAP_RADIUS * map_zoom / MAX_ORBIT_DISTANCE
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

    var player_ship: Node2D = get_tree().get_first_node_in_group("player_ship") as Node2D
    if player_ship != null:
        var player_position_scale: float = MAP_RADIUS / MAX_ORBIT_DISTANCE
        var player_map_position: Vector2 = MAP_CENTER + (player_ship.global_position * player_position_scale)
        var player_offset: Vector2 = player_map_position - MAP_CENTER
        if player_offset.length() > MAP_RADIUS - 10.0:
            player_map_position = MAP_CENTER + player_offset.normalized() * (MAP_RADIUS - 10.0)

        player_marker.position = player_map_position
        player_marker.visible = true
        player_label.position = player_map_position + Vector2(10.0, -10.0)
        player_label.visible = true
    else:
        player_marker.visible = false
        player_label.visible = false

    _update_traffic_markers()

    for station_index: int in range(station_markers.size()):
        var marker: Polygon2D = station_markers[station_index]
        var label: Label = station_labels[station_index]

        if station_index >= generated_system.stations.size():
            marker.visible = false
            label.visible = false
            station_buttons[station_index].visible = false
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
        station_buttons[station_index].text = station.display_name
        station_buttons[station_index].visible = true

func _on_map_gui_input(event: InputEvent) -> void:
    if not map_open:
        return
    if event is not InputEventMouseButton:
        return

    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if not mouse_event.pressed:
        return

    if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
        map_zoom = minf(MAX_MAP_ZOOM, map_zoom + MAP_ZOOM_STEP)
        update_map()
    elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        map_zoom = maxf(MIN_MAP_ZOOM, map_zoom - MAP_ZOOM_STEP)
        update_map()

func _update_traffic_markers() -> void:
    var civilian_index: int = 0
    var freighter_index: int = 0

    for traffic_node: Node in get_tree().get_nodes_in_group("civilian_ship"):
        var civilian_ship: CivilianShip = traffic_node as CivilianShip
        if civilian_ship == null:
            continue

        var map_position: Vector2 = _world_to_map_position(civilian_ship.global_position)

        if civilian_ship is FreighterShip:
            if freighter_index >= freighter_markers.size():
                continue
            freighter_markers[freighter_index].position = map_position
            freighter_markers[freighter_index].visible = true
            freighter_index += 1
        else:
            if civilian_index >= civilian_markers.size():
                continue
            civilian_markers[civilian_index].position = map_position
            civilian_markers[civilian_index].visible = true
            civilian_index += 1

    while civilian_index < civilian_markers.size():
        civilian_markers[civilian_index].visible = false
        civilian_index += 1

    while freighter_index < freighter_markers.size():
        freighter_markers[freighter_index].visible = false
        freighter_index += 1

func _world_to_map_position(world_position: Vector2) -> Vector2:
    var position_scale: float = MAP_RADIUS * map_zoom / MAX_ORBIT_DISTANCE
    var map_offset: Vector2 = world_position * position_scale
    var maximum_radius: float = MAP_RADIUS - 8.0

    if map_offset.length() > maximum_radius:
        map_offset = map_offset.normalized() * maximum_radius

    return MAP_CENTER + map_offset

func build_map_circle_points(radius: float) -> PackedVector2Array:
    var points: PackedVector2Array = PackedVector2Array()
    var point_count: int = 72
    var position_scale: float = MAP_RADIUS / MAX_ORBIT_DISTANCE

    for point_index: int in range(point_count + 1):
        var angle: float = TAU * float(point_index) / float(point_count)
        points.append(Vector2(cos(angle), sin(angle)) * radius * position_scale)

    return points

func update_warp_state() -> void:
    if space_system == null:
        return

    var current_system_id: String = WorldState.current_system_id
    var is_current_system: bool = selected_system_id == current_system_id
    var is_dangerous: bool = space_system.is_player_in_danger_zone()

    warp_button.disabled = is_current_system or is_dangerous
    hyperdrive_button.disabled = selected_station_id.is_empty() or is_dangerous

    if is_current_system:
        status_label.text = "Current system"
    elif is_dangerous:
        status_label.text = "Travel unavailable: hostile activity detected"
    else:
        status_label.text = "Ready to travel to %s" % get_system_name(selected_system_id)

func _select_station(station_index: int) -> void:
    if space_system == null:
        return
    if station_index < 0 or station_index >= space_system.generated_system.stations.size():
        return

    var station: GeneratedStationData = space_system.generated_system.stations[station_index]
    selected_station_id = station.id
    update_warp_state()

func _hyperdrive_to_selected_station() -> void:
    if selected_station_id.is_empty():
        return
    if space_system.is_player_in_danger_zone():
        status_label.text = "Hyperdrive unavailable: hostile activity detected"
        return

    var station_position: Vector2 = space_system.get_station_position(selected_station_id)
    var player_ship: CharacterBody2D = get_tree().get_first_node_in_group("player_ship") as CharacterBody2D
    if player_ship == null:
        return

    player_ship.global_position = station_position + Vector2(-220.0, 0.0)
    player_ship.velocity = Vector2.ZERO
    close_map()

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
