class_name Planet
extends Node3D

## Runtime planet.
##
## PlanetData supplies authored textures and physical properties. The Planet
## scene owns the meshes and applies those properties to runtime materials.

@export_category("Planet Definition")
@export var planet_data: PlanetData

@export_category("Planetary Boundary")
## Distance outside the visual planet where the warning/exclusion zone begins.
@export var exclusion_zone_height_m: float = 8.0
## Acceleration used to steer ships away from the planet while inside the
## exclusion zone. The hard planet collision remains the final barrier.
@export var exclusion_safety_acceleration_mps2: float = 80.0

@onready var planet_body: MeshInstance3D = $PlanetBody
@onready var planet_collision: StaticBody3D = $PlanetCollision
@onready var atmosphere: MeshInstance3D = $Atmosphere
@onready var clouds: MeshInstance3D = $Clouds
@onready var exclusion_zone: Area3D = $ExclusionZone

var surface_material: StandardMaterial3D
var atmosphere_material: ShaderMaterial
var cloud_material: ShaderMaterial
var ships_in_exclusion_zone: Dictionary = {}

signal planetary_exclusion_zone_entered(ship: Ship)
signal planetary_exclusion_zone_exited(ship: Ship)


func _ready() -> void:
	if exclusion_zone != null:
		exclusion_zone.body_entered.connect(_on_exclusion_zone_body_entered)
		exclusion_zone.body_exited.connect(_on_exclusion_zone_body_exited)

	_apply_planet_data()


func _physics_process(delta: float) -> void:
	_apply_exclusion_safety(delta)


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
	_configure_exclusion_zone(radius)

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

func _configure_exclusion_zone(radius: float) -> void:
	if exclusion_zone == null:
		return

	var exclusion_radius: float = radius + maxf(exclusion_zone_height_m, 0.0)
	exclusion_zone.scale = Vector3(
		exclusion_radius,
		exclusion_radius,
		exclusion_radius
	)
	exclusion_zone.monitoring = true
	exclusion_zone.monitorable = false


func _on_exclusion_zone_body_entered(body: Node3D) -> void:
	var ship: Ship = body as Ship
	if ship == null:
		return

	ships_in_exclusion_zone[ship] = true
	planetary_exclusion_zone_entered.emit(ship)


func _on_exclusion_zone_body_exited(body: Node3D) -> void:
	var ship: Ship = body as Ship
	if ship == null:
		return

	ships_in_exclusion_zone.erase(ship)
	planetary_exclusion_zone_exited.emit(ship)


func _apply_exclusion_safety(delta: float) -> void:
	if ships_in_exclusion_zone.is_empty():
		return

	var safety_acceleration: float = maxf(
		exclusion_safety_acceleration_mps2,
		0.0
	)

	if safety_acceleration <= 0.0:
		return

	var active_ships: Array[Ship] = []

	for body: Variant in ships_in_exclusion_zone.keys():
		var ship: Ship = body as Ship

		if ship == null or not is_instance_valid(ship):
			continue

		active_ships.append(ship)

	for ship: Ship in active_ships:
		var offset: Vector3 = ship.global_position - global_position
		var offset_length_squared: float = offset.length_squared()

		if offset_length_squared <= 0.0001:
			continue

		var outward_direction: Vector3 = offset.normalized()
		var current_speed: float = ship.get_speed()

		if current_speed <= 0.001:
			continue

		var desired_velocity: Vector3 = outward_direction * current_speed
		ship.velocity = ship.velocity.move_toward(
			desired_velocity,
			safety_acceleration * delta
		)


