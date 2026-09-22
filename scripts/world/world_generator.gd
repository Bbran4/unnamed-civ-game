class_name WorldGenerator
extends RefCounted

const DEFAULT_WIDTH := 64
const DEFAULT_HEIGHT := 64

const TERRAIN_WATER := 0
const TERRAIN_PLAINS := 1
const TERRAIN_FOREST := 2
const TERRAIN_MOUNTAIN := 3
const TERRAIN_DESERT := 4

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

	return {
		"seed": seed_value,
		"width": width,
		"height": height,
		"terrain": terrain
	}

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
