extends Node

const SYSTEM_SEEDS: Dictionary = {
	"asterion": 18472931,
	"caldera": 29485177,
	"nexus": 41826359
}

const DEFAULT_PLANET_COUNT: int = 5
const DEFAULT_STATION_COUNT: int = 5
const INTER_SYSTEM_DISTANCE: float = 90000.0
const INTER_SYSTEM_FUEL_COST: float = 60.0
const INTER_SYSTEM_TRANSIT_TIME: float = 45.0

var _systems: Dictionary = {}

func get_or_create_system(system_id: String, planet_count: int = DEFAULT_PLANET_COUNT, station_count: int = DEFAULT_STATION_COUNT) -> GeneratedSystemData:
	if _systems.has(system_id):
		return _systems[system_id] as GeneratedSystemData

	var system_seed: int = int(SYSTEM_SEEDS.get(system_id, 0))
	var generator: SystemGenerator = SystemGenerator.new()
	generator.planet_count = planet_count
	generator.station_count = station_count

	var generated_system: GeneratedSystemData = generator.generate_system(system_seed)
	generated_system.id = system_id

	for station_index: int in range(generated_system.stations.size()):
		var station: GeneratedStationData = generated_system.stations[station_index]
		station.id = "%s_station_%d" % [system_id, station_index]

	_systems[system_id] = generated_system
	return generated_system

func get_system(system_id: String) -> GeneratedSystemData:
	return get_or_create_system(system_id)

func get_all_system_ids() -> Array[String]:
	var system_ids: Array[String] = []
	for system_id: String in SYSTEM_SEEDS.keys():
		system_ids.append(system_id)
	return system_ids

func get_orbit_angle(system: GeneratedSystemData, initial_angle: float, period: float) -> float:
	var orbital_speed: float = TAU / maxf(period, 1.0)
	return initial_angle + orbital_speed * system.simulation_time

func get_planet_position(system_id: String, planet_id: String) -> Vector2:
	var system: GeneratedSystemData = get_system(system_id)
	for planet: GeneratedPlanetData in system.planets:
		if planet.id != planet_id:
			continue
		var angle: float = get_orbit_angle(system, planet.orbital_angle, planet.orbital_period)
		return Vector2(cos(angle), sin(angle)) * planet.orbital_distance
	return Vector2.ZERO

func get_planet_velocity(system_id: String, planet_id: String, orbit_time_scale: float) -> Vector2:
	var system: GeneratedSystemData = get_system(system_id)
	for planet: GeneratedPlanetData in system.planets:
		if planet.id != planet_id:
			continue
		var orbital_speed: float = (TAU / maxf(planet.orbital_period, 1.0)) * orbit_time_scale
		var angle: float = get_orbit_angle(system, planet.orbital_angle, planet.orbital_period)
		return Vector2(-sin(angle), cos(angle)) * planet.orbital_distance * orbital_speed
	return Vector2.ZERO

func get_station_position(system_id: String, station_id: String) -> Vector2:
	var system: GeneratedSystemData = get_system(system_id)
	for station: GeneratedStationData in system.stations:
		if station.id != station_id:
			continue
		var planet_position: Vector2 = get_planet_position(system_id, station.planet_id)
		var station_angle: float = get_orbit_angle(system, station.orbital_angle, station.orbital_period)
		var station_offset: Vector2 = Vector2(cos(station_angle), sin(station_angle)) * station.orbital_distance
		return planet_position + station_offset
	return Vector2.ZERO

func get_station_velocity(system_id: String, station: GeneratedStationData, orbit_time_scale: float) -> Vector2:
	var planet_velocity: Vector2 = get_planet_velocity(system_id, station.planet_id, orbit_time_scale)
	var system: GeneratedSystemData = get_system(system_id)
	var orbital_speed: float = (TAU / maxf(station.orbital_period, 1.0)) * orbit_time_scale
	var station_angle: float = get_orbit_angle(system, station.orbital_angle, station.orbital_period)
	var local_velocity: Vector2 = Vector2(-sin(station_angle), cos(station_angle)) * station.orbital_distance * orbital_speed
	return planet_velocity + local_velocity
