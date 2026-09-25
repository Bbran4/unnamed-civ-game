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
\tvar planet_data: PlanetData = load(PLANET_DATA_PATH) as PlanetData

\tif planet_data == null:
\t\tpush_error("Planet texture baker could not load PlanetData: " + PLANET_DATA_PATH)
\t\treturn

\tvar output_directory: DirAccess = DirAccess.open("res://assets/textures/planets/")
\tif output_directory == null:
\t\tpush_error("Planet texture baker could not access the planet texture directory.")
\t\treturn

\tif not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY)):
\t\tvar directory_error: Error = DirAccess.make_dir_recursive_absolute(
\t\t\tProjectSettings.globalize_path(OUTPUT_DIRECTORY)
\t\t)
\t\tif directory_error != OK:
\t\t\tpush_error("Planet texture baker could not create: " + OUTPUT_DIRECTORY)
\t\t\treturn

\tvar image: Image = _generate_surface(planet_data.generation_seed)
\tvar output_path: String = OUTPUT_DIRECTORY + OUTPUT_FILENAME
\tvar save_error: Error = image.save_png(output_path)

\tif save_error != OK:
\t\tpush_error("Planet texture baker could not save: " + output_path)
\t\treturn

\tprint("Planet surface baked: " + output_path)


func _generate_surface(seed: int) -> Image:
\tvar image: Image = Image.create(
\t\tTEXTURE_WIDTH,
\t\tTEXTURE_HEIGHT,
\t\tfalse,
\t\tImage.FORMAT_RGBA8
\t)

\tvar continent_noise: FastNoiseLite = FastNoiseLite.new()
\tcontinent_noise.seed = seed
\tcontinent_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
\tcontinent_noise.frequency = CONTINENT_FREQUENCY

\tvar terrain_noise: FastNoiseLite = FastNoiseLite.new()
\tterrain_noise.seed = seed + 7919
\tterrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
\tterrain_noise.frequency = TERRAIN_FREQUENCY

\tfor y: int in range(TEXTURE_HEIGHT):
\t\tvar latitude: float = float(y) / float(TEXTURE_HEIGHT - 1)
\t\tvar latitude_angle: float = (latitude - 0.5) * PI
\t\tvar latitude_cosine: float = cos(latitude_angle)

\t\tfor x: int in range(TEXTURE_WIDTH):
\t\t\tvar longitude: float = float(x) / float(TEXTURE_WIDTH) * TAU
\t\t\tvar sphere_position: Vector3 = Vector3(
\t\t\t\tcos(latitude_angle) * cos(longitude),
\t\t\t\tsin(latitude_angle),
\t\t\t\tcos(latitude_angle) * sin(longitude)
\t\t\t)

\t\t\tvar continent_value: float = (
\t\t\t\tcontinent_noise.get_noise_3dv(sphere_position) + 1.0
\t\t\t) * 0.5

\t\t\tvar land_mask: float = smoothstep(
\t\t\t\tCONTINENT_THRESHOLD - LAND_EDGE,
\t\t\t\tCONTINENT_THRESHOLD + LAND_EDGE,
\t\t\t\tcontinent_value
\t\t\t)

\t\t\tvar terrain_value: float = (
\t\t\t\tterrain_noise.get_noise_3dv(sphere_position) + 1.0
\t\t\t) * 0.5

\t\t\tvar land_color: Color = LAND_LOW_COLOR.lerp(
\t\t\t\tLAND_HIGH_COLOR,
\t\t\t\tterrain_value
\t\t\t)

\t\t\tvar polar_mask: float = smoothstep(0.70, 0.96, abs(latitude_cosine))
\t\t\tvar final_land_color: Color = land_color.lerp(
\t\t\t\tPOLAR_COLOR,
\t\t\t\tpolar_mask * 0.85
\t\t\t)

\t\t\tvar ocean_depth: float = clampf(
\t\t\t\t1.0 - continent_value,
\t\t\t\t0.0,
\t\t\t\t1.0
\t\t\t)

\t\t\tvar ocean_color: Color = OCEAN_COLOR.lerp(
\t\t\t\tSHALLOW_OCEAN_COLOR,
\t\t\t\tocean_depth * 0.35
\t\t\t)

\t\t\tvar final_color: Color = ocean_color.lerp(
\t\t\t\tfinal_land_color,
\t\t\t\tland_mask
\t\t\t)

\t\t\timage.set_pixel(x, y, final_color)

\treturn image
