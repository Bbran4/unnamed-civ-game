extends Node

## Persistent registry of every star system's generated world/economy data.
##
## Previously each StarSystem scene regenerated its planets, stations and
## markets from scratch every time it was loaded, so trading progress was
## lost whenever the player (or a freighter) left a system. GalaxyState
## generates each system once, keeps the same GeneratedSystemData object
## for the whole session, and lets freighters buy and sell against systems
## that are not even currently loaded. This is what makes real
## station-to-station AND system-to-system trade possible.

const SYSTEM_SEEDS: Dictionary = {
	"asterion": 18472931,
	"caldera": 29485177,
	"nexus": 41826359
}

const DEFAULT_PLANET_COUNT: int = 5
const DEFAULT_STATION_COUNT: int = 5

## Abstracted distance/fuel/time used for a freighter jump between systems.
## There is no rendered flight between systems, so a jump is represented as
## the freighter departing its current system and the cargo arriving after
## INTER_SYSTEM_TRANSIT_TIME seconds, updating the destination market even
## if nobody is currently there to see it happen.
const INTER_SYSTEM_DISTANCE: float = 90000.0
const INTER_SYSTEM_FUEL_COST: float = 60.0
const INTER_SYSTEM_TRANSIT_TIME: float = 45.0

var _systems: Dictionary = {}
var _pending_shipments: Array[Dictionary] = []

func _process(delta: float) -> void:
	if _pending_shipments.is_empty():
		return

	var still_pending: Array[Dictionary] = []

	for shipment: Dictionary in _pending_shipments:
		var remaining_time: float = float(shipment.get("remaining_time", 0.0)) - delta
		if remaining_time <= 0.0:
			_deliver_shipment(shipment)
		else:
			shipment["remaining_time"] = remaining_time
			still_pending.append(shipment)

	_pending_shipments = still_pending

## Returns the persistent GeneratedSystemData for system_id, generating and
## caching it on first request. Every later call (from any system, loaded
## or not) returns the exact same object, so mutations from trading persist.
func get_or_create_system(
	system_id: String,
	planet_count: int = DEFAULT_PLANET_COUNT,
	station_count: int = DEFAULT_STATION_COUNT
) -> GeneratedSystemData:
	if _systems.has(system_id):
		return _systems[system_id] as GeneratedSystemData

	var system_seed: int = int(SYSTEM_SEEDS.get(system_id, 0))
	var generator: SystemGenerator = SystemGenerator.new()
	generator.planet_count = planet_count
	generator.station_count = station_count

	var generated_system: GeneratedSystemData = generator.generate_system(system_seed)
	generated_system.id = system_id
	_systems[system_id] = generated_system
	return generated_system

func get_system(system_id: String) -> GeneratedSystemData:
	return get_or_create_system(system_id)

func get_all_system_ids() -> Array[String]:
	var system_ids: Array[String] = []
	for system_id: String in SYSTEM_SEEDS.keys():
		system_ids.append(system_id)
	return system_ids

## Queues cargo that a freighter purchased before jumping to another system.
## The manifest format matches FreighterShip's cargo_manifest.
func queue_shipment(
	destination_system_id: String,
	destination_station_id: String,
	manifest: Dictionary
) -> void:
	if manifest.is_empty():
		return

	_pending_shipments.append({
		"destination_system_id": destination_system_id,
		"destination_station_id": destination_station_id,
		"manifest": manifest.duplicate(true),
		"remaining_time": INTER_SYSTEM_TRANSIT_TIME
	})

func _deliver_shipment(shipment: Dictionary) -> void:
	var destination_system: GeneratedSystemData = get_or_create_system(
		String(shipment.get("destination_system_id", ""))
	)
	var destination_station_id: String = String(shipment.get("destination_station_id", ""))
	var destination_station: GeneratedStationData = null

	for station: GeneratedStationData in destination_system.stations:
		if station.id == destination_station_id:
			destination_station = station
			break

	if destination_station == null or destination_station.market == null or destination_station.station_type == null:
		return

	var manifest: Dictionary = shipment.get("manifest", {})
	var market: Market = Market.new()

	for item_id: String in manifest.keys():
		var cargo_entry: Dictionary = manifest[item_id]
		var units: int = int(cargo_entry.get("units", 0))
		if units <= 0:
			continue

		var current_supply: float = float(destination_station.market.supply.get(item_id, 0.0))
		destination_station.market.supply[item_id] = current_supply + float(units)

		var base_value: float = float(cargo_entry.get("base_value", 0.0))
		if base_value <= 0.0:
			continue

		var demand: float = float(destination_station.market.demand.get(item_id, 0.0))
		var is_producer: bool = _station_exports_item(
			destination_station,
			item_id,
			bool(cargo_entry.get("is_resource", false))
		)

		destination_station.market.current_prices[item_id] = market.calculate_price(
			base_value,
			float(destination_station.market.supply.get(item_id, 0.0)),
			demand,
			is_producer
		)

func _station_exports_item(station: GeneratedStationData, item_id: String, is_resource: bool) -> bool:
	if station.station_type == null:
		return false

	if is_resource:
		for resource_data: ResourceData in station.station_type.resource_exports:
			if resource_data != null and resource_data.id == item_id:
				return true
	else:
		for good_data: GoodData in station.station_type.good_exports:
			if good_data != null and good_data.id == item_id:
				return true

	return false
