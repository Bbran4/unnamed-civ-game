@tool
class_name PlanetTextureBaker
extends RefCounted

## Offline planet surface texture baker.
##
## Generates an equirectangular albedo texture for a PlanetData resource on
## the CPU, once. The result is an ordinary PNG asset, so runtime planet
## rendering never runs procedural noise per pixel and the texture can be
## hand-touched afterward.
##
## This class contains no editor UI. The Planet Baker dock
## (addons/planet_baker/) calls into it; other editor tools can too.

const TEXTURE_WIDTH: int = 2048
const TEXTURE_HEIGHT: int = 1024

const CONTINENT_FREQUENCY: float = 1.15
const CONTINENT_THRESHOLD: float = 0.51
const LAND_EDGE: float = 0.035
const TERRAIN_FREQUENCY: float = 3.0
const BAND_FREQUENCY: float = 2.0

const OCEAN_COLOR: Color = Color(0.025, 0.10, 0.28, 1.0)
const SHALLOW_OCEAN_COLOR: Color = Color(0.04, 0.24, 0.38, 1.0)
const TERRAN_LAND_LOW_COLOR: Color = Color(0.16, 0.30, 0.12, 1.0)
const TERRAN_LAND_HIGH_COLOR: Color = Color(0.46, 0.38, 0.18, 1.0)

const ICE_OCEAN_COLOR: Color = Color(0.05, 0.16, 0.32, 1.0)
const ICE_LAND_LOW_COLOR: Color = Color(0.65, 0.74, 0.8, 1.0)
const ICE_LAND_HIGH_COLOR: Color = Color(0.92, 0.95, 0.97, 1.0)

const OCEAN_WORLD_COLOR: Color = Color(0.02, 0.09, 0.26, 1.0)
const OCEAN_WORLD_ISLAND_LOW_COLOR: Color = Color(0.2, 0.32, 0.14, 1.0)
const OCEAN_WORLD_ISLAND_HIGH_COLOR: Color = Color(0.5, 0.42, 0.2, 1.0)

const POLAR_COLOR: Color = Color(0.78, 0.84, 0.82, 1.0)

const DESERT_LOW_COLOR: Color = Color(0.55, 0.4, 0.2, 1.0)
const DESERT_HIGH_COLOR: Color = Color(0.82, 0.66, 0.38, 1.0)
const BARREN_LOW_COLOR: Color = Color(0.28, 0.26, 0.24, 1.0)
const BARREN_HIGH_COLOR: Color = Color(0.55, 0.52, 0.48, 1.0)
const VOLCANIC_LOW_COLOR: Color = Color(0.06, 0.04, 0.04, 1.0)
const VOLCANIC_HIGH_COLOR: Color = Color(0.62, 0.16, 0.05, 1.0)

const GAS_GIANT_BAND_COLOR_A: Color = Color(0.55, 0.38, 0.18, 1.0)
const GAS_GIANT_BAND_COLOR_B: Color = Color(0.82, 0.66, 0.4, 1.0)


## Generate the surface Image for a PlanetData resource without saving it.
static func bake_image(planet_data: PlanetData) -> Image:
	if planet_data == null:
		push_error("PlanetTextureBaker requires a PlanetData resource.")
		return null

	var image: Image = Image.create(TEXTURE_WIDTH, TEXTURE_HEIGHT, false, Image.FORMAT_RGBA8)

	var continent_noise: FastNoiseLite = _make_noise(planet_data.generation_seed, CONTINENT_FREQUENCY)
	var terrain_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 7919, TERRAIN_FREQUENCY)
	var band_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 15551, BAND_FREQUENCY)

	for y: int in range(TEXTURE_HEIGHT):
		var latitude: float = float(y) / float(TEXTURE_HEIGHT - 1)
		var latitude_angle: float = (latitude - 0.5) * PI

		for x: int in range(TEXTURE_WIDTH):
			var longitude: float = float(x) / float(TEXTURE_WIDTH) * TAU
			var sphere_position: Vector3 = Vector3(
				cos(latitude_angle) * cos(longitude),
				sin(latitude_angle),
				cos(latitude_angle) * sin(longitude)
			)

			var pixel_color: Color = _sample_surface(
				planet_data.planet_type,
				sphere_position,
				latitude_angle,
				continent_noise,
				terrain_noise,
				band_noise
			)

			image.set_pixel(x, y, pixel_color)

	return image


## Generate, save to disk and return the resulting Texture2D.
##
## output_path must be a res:// path. The editor filesystem is refreshed so
## the new texture is importable immediately.
static func bake_and_save(planet_data: PlanetData, output_path: String) -> Texture2D:
	var image: Image = bake_image(planet_data)

	if image == null:
		return null

	var output_directory: String = output_path.get_base_dir()
	var absolute_directory: String = ProjectSettings.globalize_path(output_directory)

	if not DirAccess.dir_exists_absolute(absolute_directory):
		var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)

		if directory_error != OK:
			push_error("PlanetTextureBaker could not create directory: " + output_directory)
			return null

	var save_error: Error = image.save_png(output_path)

	if save_error != OK:
		push_error("PlanetTextureBaker could not save: " + output_path)
		return null

	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()

	if filesystem != null:
		filesystem.update_file(output_path)

	return load(output_path) as Texture2D


static func _sample_surface(
	planet_type: int,
	sphere_position: Vector3,
	latitude_angle: float,
	continent_noise: FastNoiseLite,
	terrain_noise: FastNoiseLite,
	band_noise: FastNoiseLite
) -> Color:
	match planet_type:
		PlanetData.PlanetType.GAS_GIANT:
			return _sample_gas_giant(sphere_position, band_noise)
		PlanetData.PlanetType.DESERT:
			return _sample_rocky(sphere_position, terrain_noise, DESERT_LOW_COLOR, DESERT_HIGH_COLOR)
		PlanetData.PlanetType.BARREN:
			return _sample_rocky(sphere_position, terrain_noise, BARREN_LOW_COLOR, BARREN_HIGH_COLOR)
		PlanetData.PlanetType.VOLCANIC:
			return _sample_rocky(sphere_position, terrain_noise, VOLCANIC_LOW_COLOR, VOLCANIC_HIGH_COLOR)
		PlanetData.PlanetType.ICE:
			return _sample_land_and_ocean(
				sphere_position,
				latitude_angle,
				continent_noise,
				terrain_noise,
				ICE_OCEAN_COLOR,
				ICE_OCEAN_COLOR,
				ICE_LAND_LOW_COLOR,
				ICE_LAND_HIGH_COLOR,
				CONTINENT_THRESHOLD - 0.2
			)
		PlanetData.PlanetType.OCEAN:
			return _sample_land_and_ocean(
				sphere_position,
				latitude_angle,
				continent_noise,
				terrain_noise,
				OCEAN_WORLD_COLOR,
				OCEAN_WORLD_COLOR,
				OCEAN_WORLD_ISLAND_LOW_COLOR,
				OCEAN_WORLD_ISLAND_HIGH_COLOR,
				CONTINENT_THRESHOLD + 0.25
			)
		_:
			return _sample_land_and_ocean(
				sphere_position,
				latitude_angle,
				continent_noise,
				terrain_noise,
				OCEAN_COLOR,
				SHALLOW_OCEAN_COLOR,
				TERRAN_LAND_LOW_COLOR,
				TERRAN_LAND_HIGH_COLOR,
				CONTINENT_THRESHOLD
			)


static func _sample_land_and_ocean(
	sphere_position: Vector3,
	latitude_angle: float,
	continent_noise: FastNoiseLite,
	terrain_noise: FastNoiseLite,
	ocean_color: Color,
	shallow_ocean_color: Color,
	land_low_color: Color,
	land_high_color: Color,
	continent_threshold: float
) -> Color:
	var continent_value: float = (continent_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var land_mask: float = smoothstep(
		continent_threshold - LAND_EDGE,
		continent_threshold + LAND_EDGE,
		continent_value
	)

	var terrain_value: float = (terrain_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var land_color: Color = land_low_color.lerp(land_high_color, terrain_value)

	var latitude_cosine: float = cos(latitude_angle)
	var polar_mask: float = smoothstep(0.70, 0.96, absf(latitude_cosine))
	var final_land_color: Color = land_color.lerp(POLAR_COLOR, polar_mask * 0.85)

	var ocean_depth: float = clampf(1.0 - continent_value, 0.0, 1.0)
	var final_ocean_color: Color = ocean_color.lerp(shallow_ocean_color, ocean_depth * 0.35)

	return final_ocean_color.lerp(final_land_color, land_mask)


static func _sample_rocky(
	sphere_position: Vector3,
	terrain_noise: FastNoiseLite,
	low_color: Color,
	high_color: Color
) -> Color:
	var terrain_value: float = (terrain_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	return low_color.lerp(high_color, terrain_value)


static func _sample_gas_giant(sphere_position: Vector3, band_noise: FastNoiseLite) -> Color:
	var latitude_fraction: float = absf(sphere_position.y)
	var band_sample_position: Vector3 = Vector3(
		sphere_position.x * 2.0,
		sphere_position.y * 0.35,
		sphere_position.z * 2.0
	)
	var band_noise_value: float = (band_noise.get_noise_3dv(band_sample_position) + 1.0) * 0.5
	var band_position: float = latitude_fraction * 12.0 + band_noise_value * 1.4
	var band_value: float = fposmod(band_position, 1.0)

	return GAS_GIANT_BAND_COLOR_A.lerp(GAS_GIANT_BAND_COLOR_B, smoothstep(0.25, 0.75, band_value))


static func _make_noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	return noise
