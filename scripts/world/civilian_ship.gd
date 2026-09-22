class_name CivilianShip
extends CharacterBody2D

enum TravelState {
	SELECT_DESTINATION,
	TRAVEL,
	DOCKED
}

enum JourneyType {
	LOCAL_TRANSFER,
	TRADE_RUN,
	SERVICE_RUN
}

@export var travel_speed: float = 260.0
@export var acceleration: float = 120.0
@export var arrival_distance: float = 180.0
@export var dock_duration: float = 6.0
@export var simulation_visual_only: bool = false

var travel_state: TravelState = TravelState.SELECT_DESTINATION
var journey_type: JourneyType = JourneyType.LOCAL_TRANSFER
var origin_station_id: String = ""
var destination_station_id: String = ""
var dock_time_remaining: float = 0.0
var journey_time: float = 0.0
var space_system: SpaceSystem

func _ready() -> void:
	add_to_group("civilian_ship")
	space_system = get_tree().get_first_node_in_group("space_system") as SpaceSystem

func setup(start_station_id: String) -> void:
	origin_station_id = start_station_id
	travel_state = TravelState.SELECT_DESTINATION

func _physics_process(delta: float) -> void:
	if simulation_visual_only:
		return

	if space_system == null:
		space_system = get_tree().get_first_node_in_group("space_system") as SpaceSystem
		if space_system == null:
			return

	match travel_state:
		TravelState.SELECT_DESTINATION:
			_select_destination()
		TravelState.TRAVEL:
			_travel_to_destination(delta)
		TravelState.DOCKED:
			_remain_docked(delta)

func _select_destination() -> void:
	var stations: Array[GeneratedStationData] = space_system.generated_system.stations
	if stations.size() < 2:
		travel_state = TravelState.DOCKED
		dock_time_remaining = dock_duration
		return

	var origin_station: GeneratedStationData = _get_station_by_id(origin_station_id)
	if origin_station == null:
		return

	journey_type = _choose_journey_type(origin_station)

	var candidates: Array[GeneratedStationData] = []
	for station: GeneratedStationData in stations:
		if station.id == origin_station_id:
			continue
		if _is_valid_destination(station, journey_type):
			candidates.append(station)

	if candidates.is_empty():
		for station: GeneratedStationData in stations:
			if station.id != origin_station_id:
				candidates.append(station)

	if candidates.is_empty():
		return

	var destination_index: int = randi_range(0, candidates.size() - 1)
	destination_station_id = candidates[destination_index].id
	journey_time = 0.0
	travel_state = TravelState.TRAVEL
	velocity = Vector2.ZERO

func _travel_to_destination(delta: float) -> void:
	if destination_station_id.is_empty():
		travel_state = TravelState.SELECT_DESTINATION
		return

	var destination_position: Vector2 = space_system.get_station_position(destination_station_id)
	var direction: Vector2 = global_position.direction_to(destination_position)
	var distance_to_destination: float = global_position.distance_to(destination_position)
	journey_time += delta

	if distance_to_destination <= arrival_distance:
		global_position = destination_position
		velocity = Vector2.ZERO
		origin_station_id = destination_station_id
		destination_station_id = ""
		travel_state = TravelState.DOCKED
		dock_time_remaining = dock_duration
		return

	var desired_velocity: Vector2 = direction * travel_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	move_and_slide()
	rotation = velocity.angle()

func _remain_docked(delta: float) -> void:
	dock_time_remaining = maxf(0.0, dock_time_remaining - delta)
	global_position = space_system.get_station_position(origin_station_id)
	velocity = Vector2.ZERO

	if dock_time_remaining <= 0.0:
		travel_state = TravelState.SELECT_DESTINATION

func _choose_journey_type(origin_station: GeneratedStationData) -> JourneyType:
	if origin_station.station_type == null:
		return JourneyType.LOCAL_TRANSFER

	match origin_station.station_type.id:
		"trade", "shipyard":
			return JourneyType.TRADE_RUN
		"research", "military":
			return JourneyType.SERVICE_RUN
		"mining", "agricultural", "industrial", "refinery":
			return JourneyType.TRADE_RUN

	return JourneyType.LOCAL_TRANSFER

func _is_valid_destination(station: GeneratedStationData, requested_journey: JourneyType) -> bool:
	if station.station_type == null:
		return false

	match requested_journey:
		JourneyType.TRADE_RUN:
			return station.station_type.id in [
				"trade",
				"shipyard",
				"industrial",
				"refinery",
				"agricultural",
                "mining"
			]
		JourneyType.SERVICE_RUN:
			return station.station_type.id in [
				"research",
				"military",
				"shipyard",
                "trade"
			]
		JourneyType.LOCAL_TRANSFER:
			return true

	return true

func _get_station_by_id(station_id: String) -> GeneratedStationData:
	for station: GeneratedStationData in space_system.generated_system.stations:
		if station.id == station_id:
			return station

	return null
