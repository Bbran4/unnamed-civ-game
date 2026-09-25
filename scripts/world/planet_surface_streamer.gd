class_name PlanetSurfaceStreamer
extends Node3D

## Runtime streamed planetary wilderness.
##
## Terrain is generated from deterministic planet coordinates. The streamer
## keeps a small set of cube-sphere tiles around the player and replaces them
## as the player moves across the surface.
##
## This is intentionally a fixed-resolution prototype. LOD and background
## generation will be added after the streaming path is proven.

@export_category("Streaming")
@export var stream_distance_m: float = 140.0
@export var view_distance_tiles: int = 2
@export var medium_lod_distance_tiles: int = 1
@export var far_lod_distance_tiles: int = 2

@export_category("Generation")
@export var tile_resolution: int = 17
@export var tile_angular_size_degrees: float = 12.0
@export var terrain_height_m: float = 8.0
@export var continent_frequency: float = 2.2
@export var terrain_frequency: float = 7.0

var planet: Planet
var target_ship: Ship
var terrain_noise: FastNoiseLite
var continent_noise: FastNoiseLite
var loaded_tiles: Dictionary = {}
var last_center_key: String = ""

const TILE_EPSILON: float = 0.0001


func _ready() -> void:
	planet = get_parent() as Planet

	if planet == null:
		push_error("PlanetSurfaceStreamer must be a child of Planet.")
		return

	if planet.planet_data == null:
		push_error("PlanetSurfaceStreamer requires PlanetData.")
		return

	stream_distance_m = maxf(planet.planet_data.terrain_stream_distance_m, 0.0)
	view_distance_tiles = maxi(planet.planet_data.terrain_view_distance_tiles, 0)
	tile_resolution = maxi(planet.planet_data.terrain_tile_resolution, 2)
	tile_angular_size_degrees = maxf(planet.planet_data.terrain_tile_angular_size_degrees, 0.1)
	terrain_height_m = maxf(planet.planet_data.terrain_height_m, 0.0)

	_initialize_noise()


func _process(_delta: float) -> void:
	if planet == null or target_ship == null or planet.planet_data == null:
		return

	var altitude_m: float = planet.get_altitude_m(target_ship.global_position)

	if altitude_m > stream_distance_m:
		_clear_tiles()
		return

	_stream_around_ship()


func set_target_ship(ship: Ship) -> void:
	target_ship = ship


func _initialize_noise() -> void:
	var terrain_seed: int = planet.planet_data.terrain_seed

	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = terrain_seed + 7919
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.frequency = terrain_frequency

	continent_noise = FastNoiseLite.new()
	continent_noise.seed = terrain_seed + 15401
	continent_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	continent_noise.frequency = continent_frequency


func _stream_around_ship() -> void:
	var local_position: Vector3 = planet.global_transform.affine_inverse() * target_ship.global_position
	var surface_direction: Vector3 = local_position.normalized()

	if surface_direction.length_squared() <= TILE_EPSILON:
		return

	var center: Dictionary = _direction_to_tile(surface_direction)
	var center_key: String = _tile_key(
		int(center["face"]),
		int(center["x"]),
		int(center["y"])
	)

	if center_key == last_center_key and not loaded_tiles.is_empty():
		return

	last_center_key = center_key

	var desired_tiles: Dictionary = {}

	var center_face: int = int(center["face"])
	var center_x: int = int(center["x"])
	var center_y: int = int(center["y"])

	for offset_y: int in range(-view_distance_tiles, view_distance_tiles + 1):
		for offset_x: int in range(-view_distance_tiles, view_distance_tiles + 1):
			var candidate_x: int = center_x + offset_x
			var candidate_y: int = center_y + offset_y
			var candidate_direction: Vector3 = _tile_center_direction(
				center_face,
				candidate_x,
				candidate_y
			)
			var candidate_tile: Dictionary = _direction_to_tile(candidate_direction)
			var face: int = int(candidate_tile["face"])
			var tile_x: int = int(candidate_tile["x"])
			var tile_y: int = int(candidate_tile["y"])
			var key: String = _tile_key(face, tile_x, tile_y)

			var tile_distance: int = maxi(absi(offset_x), absi(offset_y))
			var desired_resolution: int = _get_lod_resolution(tile_distance)

			desired_tiles[key] = {
				"face": face,
				"x": tile_x,
				"y": tile_y,
				"resolution": desired_resolution
			}

	for key: String in desired_tiles:
		var tile_data: Dictionary = desired_tiles[key]
		var desired_resolution: int = int(tile_data["resolution"])
		var existing_tile: PlanetTerrainTile = loaded_tiles.get(key) as PlanetTerrainTile

		if existing_tile == null:
			_create_tile(
				key,
				int(tile_data["face"]),
				int(tile_data["x"]),
				int(tile_data["y"]),
				desired_resolution
			)
		elif existing_tile.resolution != desired_resolution:
			_remove_tile(key)
			_create_tile(
				key,
				int(tile_data["face"]),
				int(tile_data["x"]),
				int(tile_data["y"]),
				desired_resolution
			)

	var loaded_keys: Array = loaded_tiles.keys()

	for key_variant: Variant in loaded_keys:
		var key: String = String(key_variant)

		if not desired_tiles.has(key):
			_remove_tile(key)


func _get_lod_resolution(tile_distance: int) -> int:
	if tile_distance <= medium_lod_distance_tiles:
		return tile_resolution

	if tile_distance <= far_lod_distance_tiles:
		return maxi((tile_resolution + 1) / 2, 3)

	return maxi((tile_resolution + 3) / 4, 3)


func _create_tile(key: String, face: int, tile_x: int, tile_y: int, desired_resolution: int) -> void:
	var tile: PlanetTerrainTile = PlanetTerrainTile.new()
	tile.name = "TerrainTile_%s" % key.replace(":", "_")
	tile.setup(
		planet,
		face,
		tile_x,
		tile_y,
		desired_resolution,
		tile_angular_size_degrees,
		terrain_height_m,
		terrain_noise,
		continent_noise
	)
	add_child(tile)
	loaded_tiles[key] = tile


func _remove_tile(key: String) -> void:
	var tile: PlanetTerrainTile = loaded_tiles.get(key) as PlanetTerrainTile

	if tile != null:
		tile.queue_free()

	loaded_tiles.erase(key)


func _clear_tiles() -> void:
	last_center_key = ""

	for key_variant: Variant in loaded_tiles.keys():
		var key: String = String(key_variant)
		_remove_tile(key)


func _tile_key(face: int, tile_x: int, tile_y: int) -> String:
	return "%d:%d:%d" % [face, tile_x, tile_y]


func _tile_center_direction(face: int, tile_x: int, tile_y: int) -> Vector3:
	var tile_count: int = maxi(
		ceili(360.0 / maxf(tile_angular_size_degrees, 0.1)),
		1
	)

	var u: float = ((float(tile_x) + 0.5) / float(tile_count)) * 2.0 - 1.0
	var v: float = ((float(tile_y) + 0.5) / float(tile_count)) * 2.0 - 1.0

	return _cube_to_sphere(face, u, v)


func _direction_to_tile(direction: Vector3) -> Dictionary:
	var normalized_direction: Vector3 = direction.normalized()
	var absolute_direction: Vector3 = normalized_direction.abs()

	var face: int = 0
	var major_axis: float = absolute_direction.x

	if absolute_direction.y > major_axis:
		face = 2 if normalized_direction.y >= 0.0 else 3
		major_axis = absolute_direction.y
	elif absolute_direction.z > major_axis:
		face = 4 if normalized_direction.z >= 0.0 else 5
		major_axis = absolute_direction.z
	else:
		face = 0 if normalized_direction.x >= 0.0 else 1

	var cube_u: float
	var cube_v: float
	var denominator: float = maxf(major_axis, TILE_EPSILON)

	match face:
		0:
			cube_u = -normalized_direction.z / denominator
			cube_v = normalized_direction.y / denominator
		1:
			cube_u = -normalized_direction.z / denominator
			cube_v = normalized_direction.y / denominator
		2:
			cube_u = normalized_direction.x / denominator
			cube_v = -normalized_direction.z / denominator
		3:
			cube_u = normalized_direction.x / denominator
			cube_v = normalized_direction.z / denominator
		4:
			cube_u = normalized_direction.x / denominator
			cube_v = normalized_direction.y / denominator
		_:
			cube_u = -normalized_direction.x / denominator
			cube_v = normalized_direction.y / denominator

	var tile_count: int = maxi(
		ceili(360.0 / maxf(tile_angular_size_degrees, 0.1)),
		1
	)

	var tile_x: int = clampi(
		floori(((cube_u + 1.0) * 0.5) * float(tile_count)),
		0,
		tile_count - 1
	)
	var tile_y: int = clampi(
		floori(((cube_v + 1.0) * 0.5) * float(tile_count)),
		0,
		tile_count - 1
	)

	return {
		"face": face,
		"x": tile_x,
		"y": tile_y
	}


func _cube_to_sphere(face: int, u: float, v: float) -> Vector3:
	var cube_position: Vector3

	match face:
		0:
			cube_position = Vector3(1.0, v, -u)
		1:
			cube_position = Vector3(-1.0, v, u)
		2:
			cube_position = Vector3(u, 1.0, -v)
		3:
			cube_position = Vector3(u, -1.0, v)
		4:
			cube_position = Vector3(u, v, 1.0)
		_:
			cube_position = Vector3(-u, v, -1.0)

	return cube_position.normalized()
