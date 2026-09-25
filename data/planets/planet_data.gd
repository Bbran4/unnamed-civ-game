class_name PlanetData
extends Resource

## Static definition for a planet.
##
## PlanetData contains identity, physical properties, and authored visual
## textures. Runtime nodes and materials belong to the Planet scene.

enum PlanetType {
	TERRAN,
	DESERT,
	BARREN,
	ICE,
	OCEAN,
	VOLCANIC,
	GAS_GIANT
}

@export_category("Identity")
@export var id: StringName = &"planet"
@export var display_name: String = "Unnamed Planet"
@export var planet_type: PlanetType = PlanetType.TERRAN

@export_category("Offline Generation")
## Seed used only by editor-side texture baking tools.
## Runtime planet rendering does not read this value.
@export var generation_seed: int = 1

@export_category("Runtime Terrain")
## Seed used by deterministic runtime planetary terrain generation.
@export var terrain_seed: int = 1
## Angular width of one cube-sphere terrain tile.
@export var terrain_tile_angular_size_degrees: float = 12.0
## Number of vertices along one terrain tile edge.
@export var terrain_tile_resolution: int = 17
## Maximum terrain elevation above the planet radius.
@export var terrain_height_m: float = 8.0
## Distance from the player at which terrain tiles are kept loaded.
@export var terrain_stream_distance_m: float = 140.0
## Number of terrain tiles streamed outward from the player tile.
@export var terrain_view_distance_tiles: int = 2

@export_category("Surface")
## Equirectangular albedo texture authored for this planet.
@export var surface_texture: Texture2D

## Optional equirectangular cloud texture.
@export var cloud_texture: Texture2D

## Optional equirectangular emission texture for night-side lights.
@export var emission_texture: Texture2D

@export_category("Physical")
## Planet radius in metres.
@export var radius_m: float = 100.0

@export_category("Atmosphere")
@export var has_atmosphere: bool = true
@export var atmosphere_color: Color = Color(0.18, 0.48, 1.0, 1.0)
@export var atmosphere_density: float = 0.75
@export var atmosphere_height_m: float = 4.0
## Multiplier used by ships to model aerodynamic drag while in the atmosphere.
@export var atmospheric_drag_strength: float = 0.0

@export_category("Clouds")
@export var has_clouds: bool = true
@export var cloud_speed: float = 0.003

@export_category("Rings")
@export var has_rings: bool = false
