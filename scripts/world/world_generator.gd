class_name WorldGenerator
extends RefCounted

const DEFAULT_WIDTH := 64
const DEFAULT_HEIGHT := 64

const TERRAIN_WATER := 0
const TERRAIN_PLAINS := 1
const TERRAIN_FOREST := 2
const TERRAIN_MOUNTAIN := 3
const TERRAIN_DESERT := 4

const RESOURCE_NONE := 0
const RESOURCE_FOOD := 1
const RESOURCE_WOOD := 2
const RESOURCE_STONE := 3
const RESOURCE_FISH := 4

func generate(seed_value: int, width: int = DEFAULT_WIDTH, height: int = DEFAULT_HEIGHT) -> Dictionary:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035

	var terrain: Array[int] = []
	terrain.resize(width * height)

	for y in range(height):
		for x in range(width):
			var value := noise.get_noise_2d(float(x), float(y))
			terrain[y * width + x] = _terrain_from_noise(value)

	var resources := _generate_resources(seed_value, terrain, width, height)

	return {
		"seed": seed_value,
		"width": width,
		"height": height,
		"terrain": terrain,
		"resources": resources
	}

func _generate_resources(seed_value: int, terrain: Array[int], width: int, height: int) -> Array[int]:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value

	var resources: Array[int] = []
	resources.resize(width * height)

	for index in range(terrain.size()):
		resources[index] = _resource_from_terrain(terrain[index], random.randf())

	return resources

func _resource_from_terrain(terrain_type: int, roll: float) -> int:
	match terrain_type:
		TERRAIN_WATER:
			if roll < 0.20:
				return RESOURCE_FISH
		TERRAIN_PLAINS:
			if roll < 0.30:
				return RESOURCE_FOOD
		TERRAIN_FOREST:
			if roll < 0.30:
				return RESOURCE_WOOD
			if roll < 0.42:
				return RESOURCE_FOOD
		TERRAIN_MOUNTAIN:
			if roll < 0.35:
				return RESOURCE_STONE
		TERRAIN_DESERT:
			if roll < 0.05:
				return RESOURCE_STONE

	return RESOURCE_NONE

func _terrain_from_noise(value: float) -> int:
	if value < -0.28:
		return TERRAIN_WATER
	if value > 0.68:
		return TERRAIN_MOUNTAIN
	if value > 0.38:
		return TERRAIN_FOREST
	if value < -0.02:
		return TERRAIN_DESERT
	return TERRAIN_PLAINS
