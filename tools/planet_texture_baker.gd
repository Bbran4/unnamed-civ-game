@tool
class_name PlanetTextureBaker
extends RefCounted

## Offline planet texture baker.
##
## Generates equirectangular surface and cloud textures for a PlanetData
## resource on the CPU, once. The results are ordinary PNG assets, so runtime
## planet rendering never runs procedural noise per pixel and the textures
## can be hand-touched afterward.
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

const CLOUD_LARGE_FREQUENCY: float = 2.2
const CLOUD_DETAIL_FREQUENCY: float = 7.0
const CLOUD_WISP_FREQUENCY: float = 15.0
const DUST_FREQUENCY: float = 2.8
const HAZE_FREQUENCY: float = 4.0
const GAS_CLOUD_FREQUENCY: float = 3.5
const GAS_STORM_FREQUENCY: float = 5.0

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


## Generate atmosphere settings for a PlanetData resource.
##
## Atmosphere is a runtime optical effect rather than a baked texture, so the
## baker assigns the appropriate parameters directly to PlanetData.
static func bake_atmosphere(planet_data: PlanetData) -> void:
	if planet_data == null:
		push_error("PlanetTextureBaker requires a PlanetData resource.")
		return

	match planet_data.planet_type:
		PlanetData.PlanetType.TERRAN:
			planet_data.has_atmosphere = true
			planet_data.atmosphere_color = Color(0.18, 0.48, 1.0, 1.0)
			planet_data.atmosphere_density = 0.80
			planet_data.atmosphere_height_m = 5.0
		PlanetData.PlanetType.DESERT:
			planet_data.has_atmosphere = true
			planet_data.atmosphere_color = Color(0.72, 0.43, 0.22, 1.0)
			planet_data.atmosphere_density = 0.30
			planet_data.atmosphere_height_m = 3.0
		PlanetData.PlanetType.BARREN:
			planet_data.has_atmosphere = false
			planet_data.atmosphere_color = Color(0.35, 0.35, 0.35, 1.0)
			planet_data.atmosphere_density = 0.0
			planet_data.atmosphere_height_m = 0.5
		PlanetData.PlanetType.ICE:
			planet_data.has_atmosphere = true
			planet_data.atmosphere_color = Color(0.55, 0.78, 1.0, 1.0)
			planet_data.atmosphere_density = 0.35
			planet_data.atmosphere_height_m = 3.0
		PlanetData.PlanetType.OCEAN:
			planet_data.has_atmosphere = true
			planet_data.atmosphere_color = Color(0.12, 0.65, 1.0, 1.0)
			planet_data.atmosphere_density = 0.90
			planet_data.atmosphere_height_m = 5.0
		PlanetData.PlanetType.VOLCANIC:
			planet_data.has_atmosphere = true
			planet_data.atmosphere_color = Color(0.85, 0.20, 0.06, 1.0)
			planet_data.atmosphere_density = 0.45
			planet_data.atmosphere_height_m = 3.5
		PlanetData.PlanetType.GAS_GIANT:
			planet_data.has_atmosphere = true
			planet_data.atmosphere_color = Color(0.86, 0.68, 0.42, 1.0)
			planet_data.atmosphere_density = 0.70
			planet_data.atmosphere_height_m = 8.0


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


## Generate the cloud Image for a PlanetData resource without saving it.
##
## The result is an equirectangular RGBA texture. RGB stores the authored
## cloud/haze colour and alpha stores coverage. Barren planets receive a fully
## transparent map because they have no cloud layer.
static func bake_cloud_image(planet_data: PlanetData) -> Image:
	if planet_data == null:
		push_error("PlanetTextureBaker requires a PlanetData resource.")
		return null

	var image: Image = Image.create(TEXTURE_WIDTH, TEXTURE_HEIGHT, false, Image.FORMAT_RGBA8)

	var large_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 31337, CLOUD_LARGE_FREQUENCY)
	var detail_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 42421, CLOUD_DETAIL_FREQUENCY)
	var wisp_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 51001, CLOUD_WISP_FREQUENCY)
	var dust_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 62003, DUST_FREQUENCY)
	var haze_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 73009, HAZE_FREQUENCY)
	var gas_cloud_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 84011, GAS_CLOUD_FREQUENCY)
	var gas_storm_noise: FastNoiseLite = _make_noise(planet_data.generation_seed + 95027, GAS_STORM_FREQUENCY)

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

			var cloud_color: Color = Color(1.0, 1.0, 1.0, 0.0)

			match planet_data.planet_type:
				PlanetData.PlanetType.TERRAN:
					cloud_color = _sample_terran_clouds(
						sphere_position,
						latitude_angle,
						large_noise,
						detail_noise,
						wisp_noise
					)
				PlanetData.PlanetType.DESERT:
					cloud_color = _sample_desert_clouds(
						sphere_position,
						latitude_angle,
						dust_noise,
						haze_noise
					)
				PlanetData.PlanetType.BARREN:
					cloud_color = Color(1.0, 1.0, 1.0, 0.0)
				PlanetData.PlanetType.ICE:
					cloud_color = _sample_ice_clouds(
						sphere_position,
						latitude_angle,
						haze_noise,
						wisp_noise
					)
				PlanetData.PlanetType.OCEAN:
					cloud_color = _sample_ocean_clouds(
						sphere_position,
						latitude_angle,
						large_noise,
						detail_noise,
						gas_cloud_noise
					)
				PlanetData.PlanetType.VOLCANIC:
					cloud_color = _sample_volcanic_clouds(
						sphere_position,
						latitude_angle,
						large_noise,
						detail_noise
					)
				PlanetData.PlanetType.GAS_GIANT:
					cloud_color = _sample_gas_giant_clouds(
						sphere_position,
						latitude_angle,
						gas_cloud_noise,
						gas_storm_noise
					)

			image.set_pixel(x, y, cloud_color)

	return image


## Generate, save and return the resulting surface Texture2D.
static func bake_and_save(planet_data: PlanetData, output_path: String) -> Texture2D:
	var image: Image = bake_image(planet_data)
	return _save_image(image, output_path)


## Generate, save and return the resulting cloud Texture2D.
static func bake_clouds_and_save(planet_data: PlanetData, output_path: String) -> Texture2D:
	var image: Image = bake_cloud_image(planet_data)
	return _save_image(image, output_path)


static func _save_image(image: Image, output_path: String) -> Texture2D:
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
		filesystem.reimport_files(PackedStringArray([output_path]))

	if ResourceLoader.exists(output_path, "Texture2D"):
		var imported_texture: Texture2D = load(output_path) as Texture2D

		if imported_texture != null:
			return imported_texture

	push_warning(
		"PlanetTextureBaker: %s saved but not yet imported. Using an in-memory texture for now." % output_path
	)
	return ImageTexture.create_from_image(image)


static func _sample_terran_clouds(
	sphere_position: Vector3,
	latitude_angle: float,
	large_noise: FastNoiseLite,
	detail_noise: FastNoiseLite,
	wisp_noise: FastNoiseLite
) -> Color:
	var large_value: float = (large_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var detail_value: float = (detail_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var wisp_value: float = (wisp_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5

	var tropical_mask: float = 1.0 - _smoothstep(0.45, 0.85, absf(latitude_angle))
	var polar_mask: float = _smoothstep(0.95, 1.35, absf(latitude_angle))

	var broad_clouds: float = _smoothstep(0.47, 0.67, large_value)
	var detail_mask: float = _smoothstep(0.38, 0.72, detail_value)
	var wisps: float = _smoothstep(0.62, 0.86, wisp_value)

	var density: float = broad_clouds * (0.62 + detail_mask * 0.38)
	density += wisps * 0.16
	density *= 0.82 + tropical_mask * 0.18
	density = clampf(density + polar_mask * 0.12, 0.0, 1.0)

	return Color(0.94, 0.96, 1.0, density * 0.82)


static func _sample_desert_clouds(
	sphere_position: Vector3,
	latitude_angle: float,
	dust_noise: FastNoiseLite,
	haze_noise: FastNoiseLite
) -> Color:
	var dust_value: float = (dust_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var haze_value: float = (haze_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5

	var dust_mask: float = _smoothstep(0.57, 0.78, dust_value)
	var haze_mask: float = _smoothstep(0.63, 0.86, haze_value)
	var latitude_factor: float = 0.72 + _smoothstep(0.15, 0.75, absf(latitude_angle)) * 0.28

	var density: float = clampf((dust_mask * 0.72 + haze_mask * 0.28) * latitude_factor, 0.0, 1.0)

	return Color(0.72, 0.50, 0.28, density * 0.38)


static func _sample_ice_clouds(
	sphere_position: Vector3,
	latitude_angle: float,
	haze_noise: FastNoiseLite,
	wisp_noise: FastNoiseLite
) -> Color:
	var haze_value: float = (haze_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var wisp_value: float = (wisp_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5

	var broad_haze: float = _smoothstep(0.48, 0.74, haze_value)
	var wisps: float = _smoothstep(0.65, 0.88, wisp_value)
	var latitude_factor: float = 0.55 + _smoothstep(0.2, 1.2, absf(latitude_angle)) * 0.45

	var density: float = clampf((broad_haze * 0.45 + wisps * 0.55) * latitude_factor, 0.0, 1.0)

	return Color(0.72, 0.86, 1.0, density * 0.22)


static func _sample_ocean_clouds(
	sphere_position: Vector3,
	latitude_angle: float,
	large_noise: FastNoiseLite,
	detail_noise: FastNoiseLite,
	gas_cloud_noise: FastNoiseLite
) -> Color:
	var broad_value: float = (large_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var detail_value: float = (detail_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var storm_value: float = (gas_cloud_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5

	var bands: float = 0.5 + 0.5 * cos(latitude_angle * 8.0)
	var broad_clouds: float = _smoothstep(0.44, 0.70, broad_value)
	var detail_clouds: float = _smoothstep(0.50, 0.82, detail_value)
	var storms: float = _smoothstep(0.72, 0.92, storm_value)

	var density: float = broad_clouds * 0.52 + detail_clouds * 0.20 + storms * 0.28
	density += _smoothstep(0.62, 0.92, bands) * 0.10
	density = clampf(density, 0.0, 1.0)

	return Color(0.78, 0.90, 1.0, density * 0.70)


static func _sample_volcanic_clouds(
	sphere_position: Vector3,
	latitude_angle: float,
	large_noise: FastNoiseLite,
	detail_noise: FastNoiseLite
) -> Color:
	var large_value: float = (large_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var detail_value: float = (detail_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5

	var large_cover: float = _smoothstep(0.32, 0.58, large_value)
	var detail_variation: float = _smoothstep(0.35, 0.72, detail_value)
	var polar_brightness: float = _smoothstep(0.85, 1.35, absf(latitude_angle))

	var density: float = clampf(0.76 + large_cover * 0.16 - detail_variation * 0.12, 0.58, 0.96)
	var color_mix: float = clampf(0.72 + polar_brightness * 0.18, 0.0, 1.0)
	var cloud_color: Color = Color(0.72, 0.64, 0.48, 1.0).lerp(Color(0.92, 0.86, 0.70, 1.0), color_mix)

	return Color(cloud_color.r, cloud_color.g, cloud_color.b, density * 0.78)


static func _sample_gas_giant_clouds(
	sphere_position: Vector3,
	latitude_angle: float,
	gas_cloud_noise: FastNoiseLite,
	gas_storm_noise: FastNoiseLite
) -> Color:
	var cloud_value: float = (gas_cloud_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var storm_value: float = (gas_storm_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5

	var band_wave: float = 0.5 + 0.5 * cos(latitude_angle * 18.0)
	var band_structure: float = _smoothstep(0.15, 0.85, band_wave)

	var turbulence: float = _smoothstep(0.28, 0.72, cloud_value)
	var storms: float = _smoothstep(0.68, 0.92, storm_value)

	var cloud_density: float = 0.58
	cloud_density += band_structure * 0.18
	cloud_density += turbulence * 0.18
	cloud_density += storms * 0.16

	cloud_density = clampf(cloud_density, 0.45, 0.98)

	var cloud_tone: float = 0.35
	cloud_tone += turbulence * 0.25
	cloud_tone += storms * 0.30

	var cloud_color: Color = Color(0.68, 0.54, 0.34, 1.0).lerp(
		Color(0.96, 0.88, 0.68, 1.0),
		clampf(cloud_tone, 0.0, 1.0)
	)

	return Color(
		cloud_color.r,
		cloud_color.g,
		cloud_color.b,
		cloud_density * 0.85
	)

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
	var land_mask: float = _smoothstep(
		continent_threshold - LAND_EDGE,
		continent_threshold + LAND_EDGE,
		continent_value
	)

	var terrain_value: float = (terrain_noise.get_noise_3dv(sphere_position) + 1.0) * 0.5
	var land_color: Color = land_low_color.lerp(land_high_color, terrain_value)

	var latitude_cosine: float = cos(latitude_angle)
	var polar_mask: float = _smoothstep(0.70, 0.96, absf(latitude_cosine))
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

	return GAS_GIANT_BAND_COLOR_A.lerp(GAS_GIANT_BAND_COLOR_B, _smoothstep(0.25, 0.75, band_value))


static func _smoothstep(edge_0: float, edge_1: float, value: float) -> float:
	var t: float = clampf((value - edge_0) / (edge_1 - edge_0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _make_noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	return noise
