@tool
extends EditorScript

## Offline planet surface texture baker.
##
## Run this script from the Godot script editor with File > Run.
## The baker reads PlanetData, generates an equirectangular PNG, and leaves
## the result as an ordinary texture asset that can be edited by hand.

const PLANET_DATA_PATH: String = "res://data/planets/starter_planet.tres"
const OUTPUT_DIRECTORY: String = "res://assets/textures/planets/generated/"
const OUTPUT_FILENAME: String = "asteron_surface_baked.png"

const TEXTURE_WIDTH: int = 2048
const TEXTURE_HEIGHT: int = 1024

const OCEAN_COLOR: Color = Color(0.025, 0.10, 0.28, 1.0)
const SHALLOW_OCEAN_COLOR: Color = Color(0.04, 0.24, 0.38, 1.0)
const LAND_LOW_COLOR: Color = Color(0.16, 0.30, 0.12, 1.0)
const LAND_HIGH_COLOR: Color = Color(0.46, 0.38, 0.18, 1.0)
const POLAR_COLOR: Color = Color(0.78, 0.84, 0.82, 1.0)

const CONTINENT_FREQUENCY: float = 1.15
const TERRAIN_FREQUENCY: float = 3.0
const CONTINENT_THRESHOLD: float = 0.51
const LAND_EDGE: float = 0.035


func _run() -> void:
	var planet_data: PlanetData = load(PLANET_DATA_PATH) as PlanetData

	if planet_data == null:
		push_error("Planet texture baker could not load PlanetData: " + PLANET_DATA_PATH)
		return

	var output_directory: DirAccess = DirAccess.open("res://assets/textures/planets/")
	if output_directory == null:
		push_error("Planet texture baker could not access the planet texture directory.")
		return

	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY)):
		var directory_error: Error = DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
		)
		if directory_error != OK:
			push_error("Planet texture baker could not create: " + OUTPUT_DIRECTORY)
			return

	var image: Image = _generate_surface(planet_data.generation_seed)
	var output_path: String = OUTPUT_DIRECTORY + OUTPUT_FILENAME
	var save_error: Error = image.save_png(output_path)

	if save_error != OK:
		push_error("Planet texture baker could not save: " + output_path)
		return

	print("Planet surface baked: " + output_path)


func _generate_surface(seed: int) -> Image:
	var image: Image = Image.create(
		TEXTURE_WIDTH,
		TEXTURE_HEIGHT,
		false,
		Image.FORMAT_RGBA8
	)

	var continent_noise: FastNoiseLite = FastNoiseLite.new()
	continent_noise.seed = seed
	continent_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	continent_noise.frequency = CONTINENT_FREQUENCY

	var terrain_noise: FastNoiseLite = FastNoiseLite.new()
	terrain_noise.seed = seed + 7919
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.frequency = TERRAIN_FREQUENCY

	for y: int in range(TEXTURE_HEIGHT):
		var latitude: float = float(y) / float(TEXTURE_HEIGHT - 1)
		var latitude_angle: float = (latitude - 0.5) * PI
		var latitude_cosine: float = cos(latitude_angle)

		for x: int in range(TEXTURE_WIDTH):
			var longitude: float = float(x) / float(TEXTURE_WIDTH) * TAU
			var sphere_position: Vector3 = Vector3(
				cos(latitude_angle) * cos(longitude),
				sin(latitude_angle),
				cos(latitude_angle) * sin(longitude)
			)

			var continent_value: float = (
				continent_noise.get_noise_3dv(sphere_position) + 1.0
			) * 0.5

			var land_mask: float = smoothstep(
				CONTINENT_THRESHOLD - LAND_EDGE,
				CONTINENT_THRESHOLD + LAND_EDGE,
				continent_value
			)

			var terrain_value: float = (
				terrain_noise.get_noise_3dv(sphere_position) + 1.0
			) * 0.5

			var land_color: Color = LAND_LOW_COLOR.lerp(
				LAND_HIGH_COLOR,
				terrain_value
			)

			var polar_mask: float = smoothstep(0.70, 0.96, abs(latitude_cosine))
			var final_land_color: Color = land_color.lerp(
				POLAR_COLOR,
				polar_mask * 0.85
			)

			var ocean_depth: float = clampf(
				1.0 - continent_value,
				0.0,
				1.0
			)

			var ocean_color: Color = OCEAN_COLOR.lerp(
				SHALLOW_OCEAN_COLOR,
				ocean_depth * 0.35
			)

			var final_color: Color = ocean_color.lerp(
				final_land_color,
				land_mask
			)

			image.set_pixel(x, y, final_color)

	return image
