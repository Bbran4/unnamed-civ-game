class_name Planet
extends Node3D

## Runtime planet.
##
## PlanetData supplies the static definition. This scene owns the actual
## planet meshes and applies the data to their materials.

@export_category("Planet Definition")
@export var planet_data: PlanetData

@onready var planet_body: MeshInstance3D = $PlanetBody
@onready var atmosphere: MeshInstance3D = $Atmosphere
@onready var clouds: MeshInstance3D = $Clouds

var surface_material: ShaderMaterial
var atmosphere_material: ShaderMaterial
var cloud_material: ShaderMaterial


func _ready() -> void:
	_apply_planet_data()


func _apply_planet_data() -> void:
	if planet_data == null:
		push_error("Planet requires PlanetData.")
		return

	var radius: float = maxf(planet_data.radius_m, 1.0)

	planet_body.scale = Vector3(radius, radius, radius)
	atmosphere.scale = Vector3(
		radius + maxf(planet_data.atmosphere_height_m, 0.1),
		radius + maxf(planet_data.atmosphere_height_m, 0.1),
		radius + maxf(planet_data.atmosphere_height_m, 0.1)
	)
	clouds.scale = Vector3(
		radius * 1.004,
		radius * 1.004,
		radius * 1.004
	)

	surface_material = planet_body.material_override as ShaderMaterial
	atmosphere_material = atmosphere.material_override as ShaderMaterial
	cloud_material = clouds.material_override as ShaderMaterial

	if surface_material != null:
		surface_material.set_shader_parameter("generation_seed", float(planet_data.generation_seed))
		surface_material.set_shader_parameter("continent_noise_scale", planet_data.continent_noise_scale)
		surface_material.set_shader_parameter("continent_threshold", planet_data.continent_threshold)
		surface_material.set_shader_parameter("surface_color_a", planet_data.surface_color_a)
		surface_material.set_shader_parameter("surface_color_b", planet_data.surface_color_b)
		surface_material.set_shader_parameter("ocean_color", planet_data.ocean_color)
		surface_material.set_shader_parameter("noise_scale", planet_data.surface_noise_scale)
		surface_material.set_shader_parameter("noise_strength", planet_data.surface_noise_strength)
		surface_material.set_shader_parameter("surface_contrast", planet_data.surface_contrast)

	if atmosphere_material != null:
		atmosphere_material.set_shader_parameter("atmosphere_color", planet_data.atmosphere_color)
		atmosphere_material.set_shader_parameter("atmosphere_density", planet_data.atmosphere_density)

	atmosphere.visible = planet_data.has_atmosphere
	clouds.visible = planet_data.has_clouds

	if cloud_material != null:
		cloud_material.set_shader_parameter("cloud_density", planet_data.cloud_density)
		cloud_material.set_shader_parameter("cloud_speed", planet_data.cloud_speed)
