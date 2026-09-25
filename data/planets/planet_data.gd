class_name PlanetData
extends Resource

## Static definition for a planet.
##
## PlanetData contains the identity and visual inputs for one planet.
## Runtime nodes and generated materials belong to the Planet scene.

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

@export_category("Generation")
## The same seed always produces the same surface pattern.
@export var generation_seed: int = 1
@export var continent_noise_scale: float = 1.35
@export_range(0.0, 1.0, 0.01) var continent_threshold: float = 0.55

@export_category("Physical")
## Planet radius in metres.
@export var radius_m: float = 100.0

@export_category("Surface")
@export var surface_color_a: Color = Color(0.16, 0.32, 0.14, 1.0)
@export var surface_color_b: Color = Color(0.45, 0.36, 0.18, 1.0)
@export var ocean_color: Color = Color(0.03, 0.12, 0.28, 1.0)
@export var surface_noise_scale: float = 2.2
@export var surface_noise_strength: float = 0.75
@export var surface_contrast: float = 1.35

@export_category("Atmosphere")
@export var has_atmosphere: bool = true
@export var atmosphere_color: Color = Color(0.18, 0.48, 1.0, 1.0)
@export var atmosphere_density: float = 0.75
@export var atmosphere_height_m: float = 4.0

@export_category("Clouds")
@export var has_clouds: bool = true
@export var cloud_density: float = 0.35
@export var cloud_speed: float = 0.003

@export_category("Rings")
@export var has_rings: bool = false
