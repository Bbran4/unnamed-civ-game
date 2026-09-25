class_name Planet
extends Node3D

## Runtime planet.
##
## PlanetData supplies authored textures and physical properties. The Planet
## scene owns the meshes and applies those properties to runtime materials.

@export_category("Planet Definition")
@export var planet_data: PlanetData

@onready var planet_body: MeshInstance3D = $PlanetBody
@onready var planet_collision: StaticBody3D = $PlanetCollision
@onready var atmosphere: MeshInstance3D = $Atmosphere
@onready var clouds: MeshInstance3D = $Clouds
@onready var collision_shape: CollisionShape3D = $PlanetCollision/CollisionShape3D

var surface_material: StandardMaterial3D
var atmosphere_material: ShaderMaterial
var cloud_material: ShaderMaterial

signal flight_environment_changed(
	ship: Ship,
	environment: Ship.FlightEnvironment,
	altitude_m: float
)


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
	planet_collision.scale = Vector3(radius, radius, radius)
	atmosphere.scale = Vector3(atmosphere_radius, atmosphere_radius, atmosphere_radius)
	clouds.scale = Vector3(cloud_radius, cloud_radius, cloud_radius)

	surface_material = planet_body.material_override as StandardMaterial3D
	atmosphere_material = atmosphere.material_override as ShaderMaterial
	cloud_material = clouds.material_override as ShaderMaterial

	if surface_material != null:
		surface_material.albedo_texture = planet_data.surface_texture
		surface_material.roughness = 0.82
		surface_material.metallic = 0.0
		_apply_emission(surface_material)

	if atmosphere_material != null:
		atmosphere_material.set_shader_parameter("atmosphere_color", planet_data.atmosphere_color)
		atmosphere_material.set_shader_parameter("atmosphere_density", planet_data.atmosphere_density)

	atmosphere.visible = planet_data.has_atmosphere
	clouds.visible = planet_data.has_clouds and planet_data.cloud_texture != null

	if cloud_material != null:
		cloud_material.set_shader_parameter("cloud_texture", planet_data.cloud_texture)
		cloud_material.set_shader_parameter("cloud_speed", planet_data.cloud_speed)


func _apply_emission(material: StandardMaterial3D) -> void:
	var emission_texture: Texture2D = planet_data.emission_texture

	if emission_texture == null:
		material.emission_enabled = false
		return

	material.emission_enabled = true
	material.emission_texture = emission_texture
	material.emission_energy_multiplier = 1.0


func get_altitude_m(world_position: Vector3) -> float:
	if planet_data == null:
		return INF

	var radius: float = maxf(planet_data.radius_m, 1.0)
	var distance_from_centre: float = global_position.distance_to(world_position)
	return distance_from_centre - radius


func get_atmosphere_fraction(world_position: Vector3) -> float:
	if planet_data == null or not planet_data.has_atmosphere:
		return 0.0

	var altitude_m: float = get_altitude_m(world_position)
	var atmosphere_height_m: float = maxf(planet_data.atmosphere_height_m, 0.1)

	return clampf(
		1.0 - (altitude_m / atmosphere_height_m),
		0.0,
		1.0
	)


func get_flight_environment(world_position: Vector3) -> Ship.FlightEnvironment:
	if planet_data == null:
		return Ship.FlightEnvironment.SPACE

	var altitude_m: float = get_altitude_m(world_position)

	if altitude_m <= 0.0:
		return Ship.FlightEnvironment.SURFACE

	if planet_data.has_atmosphere and altitude_m <= planet_data.atmosphere_height_m:
		return Ship.FlightEnvironment.ATMOSPHERE

	return Ship.FlightEnvironment.SPACE


func update_ship_environment(ship: Ship) -> void:
	if ship == null:
		return

	var altitude_m: float = get_altitude_m(ship.global_position)
	var environment: Ship.FlightEnvironment = get_flight_environment(ship.global_position)
	var new_atmosphere_fraction: float = get_atmosphere_fraction(ship.global_position)

	_update_atmosphere_visuals(altitude_m)

	if ship.flight_environment == environment and ship.current_planet == self:
		ship.atmosphere_fraction = new_atmosphere_fraction
		return

	ship.set_flight_environment(
		environment,
		self if environment != Ship.FlightEnvironment.SPACE else null,
		new_atmosphere_fraction
	)
	flight_environment_changed.emit(ship, environment, altitude_m)


func _update_atmosphere_visuals(altitude_m: float) -> void:
	if atmosphere_material == null or planet_data == null:
		return

	if not planet_data.has_atmosphere:
		return

	var atmosphere_height_m: float = maxf(planet_data.atmosphere_height_m, 0.1)
	var approach_distance_m: float = atmosphere_height_m * 4.0
	var approach_fraction: float = clampf(
		1.0 - (altitude_m / approach_distance_m),
		0.0,
		1.0
	)
	var visual_density: float = lerpf(
		planet_data.atmosphere_density * 0.35,
		planet_data.atmosphere_density,
		approach_fraction
	)

	atmosphere_material.set_shader_parameter("atmosphere_density", visual_density)
