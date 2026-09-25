class_name Planet
extends Node3D

## Runtime planet.
##
## PlanetData supplies authored textures and physical properties. The Planet
## scene owns the meshes and applies those properties to runtime materials.

@export_category("Planet Definition")
@export var planet_data: PlanetData

@onready var planet_body: MeshInstance3D = $PlanetBody
@onready var atmosphere: MeshInstance3D = $Atmosphere
@onready var clouds: MeshInstance3D = $Clouds

var surface_material: StandardMaterial3D
var atmosphere_material: ShaderMaterial
var cloud_material: ShaderMaterial


func _ready() -> void:
	_apply_planet_data()


func _apply_planet_data() -> void:
	if planet_data == null:
		push_error("Planet requires PlanetData.")
		return

	var radius: float = maxf(planet_data.radius_m, 1.0)
	var atmosphere_radius: float = radius + maxf(planet_data.atmosphere_height_m, 0.1)
	var cloud_radius: float = radius * 1.004

	planet_body.scale = Vector3(radius, radius, radius)
	atmosphere.scale = Vector3(atmosphere_radius, atmosphere_radius, atmosphere_radius)
	clouds.scale = Vector3(cloud_radius, cloud_radius, cloud_radius)

	surface_material = planet_body.material_override as StandardMaterial3D
	atmosphere_material = atmosphere.material_override as ShaderMaterial
	cloud_material = clouds.material_override as ShaderMaterial

	if surface_material != null:
		surface_material.albedo_texture = planet_data.surface_texture
		surface_material.roughness = 0.82
		surface_material.metallic = 0.0

	if atmosphere_material != null:
		atmosphere_material.set_shader_parameter("atmosphere_color", planet_data.atmosphere_color)
		atmosphere_material.set_shader_parameter("atmosphere_density", planet_data.atmosphere_density)

	atmosphere.visible = planet_data.has_atmosphere
	clouds.visible = planet_data.has_clouds and planet_data.cloud_texture != null

	if cloud_material != null:
		cloud_material.set_shader_parameter("cloud_texture", planet_data.cloud_texture)
		cloud_material.set_shader_parameter("cloud_speed", planet_data.cloud_speed)
