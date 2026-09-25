class_name Planet
extends Node3D

## Runtime planet.
##
## PlanetData supplies authored textures and physical properties. The Planet
## scene owns the meshes and applies those properties to runtime materials.
##
## Planetary boundary behaviour (Freelancer-style):
## - Hard StaticBody3D collision is the final barrier (ships cannot pass through).
## - A thicker exclusion / atmosphere zone warns and registers a boundary with ships.
## - Deep inside the zone, continuous damage is applied (like Freelancer atmospheres).

@export_category("Planet Definition")
@export var planet_data: PlanetData

@export_category("Planetary Boundary")
## Minimum height of the exclusion zone outside the visual surface (metres).
## Actual height is the larger of this value and radius * exclusion_zone_radius_fraction.
@export var exclusion_zone_height_m: float = 50.0
## Fraction of planet radius added on top of the surface for the exclusion zone.
@export_range(0.0, 1.0, 0.01) var exclusion_zone_radius_fraction: float = 0.35
## Base acceleration used by a ship to steer away from the planet while inside
## the exclusion zone. Scaled up the deeper the ship is.
@export var exclusion_safety_acceleration_mps2: float = 250.0
## Extra acceleration used by a ship to remove significant inward velocity.
@export var exclusion_inward_kill_acceleration_mps2: float = 400.0
## Hull damage per second applied when a ship is deep inside the exclusion zone
## (Freelancer-style atmosphere damage). Set to 0 to disable.
@export var atmosphere_damage_per_second: float = 35.0
## Fraction of the exclusion shell (0 = outer edge, 1 = planet surface) at which
## atmosphere damage begins.
@export_range(0.0, 1.0, 0.05) var atmosphere_damage_depth_start: float = 0.45

@onready var planet_body: MeshInstance3D = $PlanetBody
@onready var planet_collision: StaticBody3D = $PlanetCollision
@onready var atmosphere: MeshInstance3D = $Atmosphere
@onready var clouds: MeshInstance3D = $Clouds
@onready var exclusion_zone: Area3D = $ExclusionZone

var surface_material: StandardMaterial3D
var atmosphere_material: ShaderMaterial
var cloud_material: ShaderMaterial
var ships_in_exclusion_zone: Dictionary = {}
var _planet_radius_m: float = 1.0
var _exclusion_radius_m: float = 1.0

signal planetary_exclusion_zone_entered(ship: Ship)
signal planetary_exclusion_zone_exited(ship: Ship)


func _ready() -> void:
	if exclusion_zone != null:
		exclusion_zone.body_entered.connect(_on_exclusion_zone_body_entered)
		exclusion_zone.body_exited.connect(_on_exclusion_zone_body_exited)

	_apply_planet_data()


func _physics_process(delta: float) -> void:
	_apply_exclusion_damage(delta)


func _apply_planet_data() -> void:
	if planet_data == null:
		push_error("Planet requires PlanetData.")
		return

	var radius: float = maxf(planet_data.radius_m, 1.0)
	_planet_radius_m = radius
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

	var height_from_fraction: float = radius * maxf(exclusion_zone_radius_fraction, 0.0)
	var exclusion_height: float = maxf(exclusion_zone_height_m, height_from_fraction)
	_exclusion_radius_m = radius + exclusion_height

	exclusion_zone.scale = Vector3(
		_exclusion_radius_m,
		_exclusion_radius_m,
		_exclusion_radius_m
	)
	exclusion_zone.monitoring = true
	exclusion_zone.monitorable = false


func _on_exclusion_zone_body_entered(body: Node3D) -> void:
	var ship: Ship = body as Ship
	if ship == null:
		return

	ships_in_exclusion_zone[ship] = true
	ship.register_planetary_boundary(self)
	planetary_exclusion_zone_entered.emit(ship)


func _on_exclusion_zone_body_exited(body: Node3D) -> void:
	var ship: Ship = body as Ship
	if ship == null:
		return

	ships_in_exclusion_zone.erase(ship)
	ship.unregister_planetary_boundary(self)
	planetary_exclusion_zone_exited.emit(ship)


func _apply_exclusion_damage(delta: float) -> void:
	if ships_in_exclusion_zone.is_empty():
		return

	var active_ships: Array[Ship] = []

	for body: Variant in ships_in_exclusion_zone.keys():
		var ship: Ship = body as Ship

		if ship == null or not is_instance_valid(ship):
			continue

		if ship.destroyed_state:
			continue

		active_ships.append(ship)

	for ship: Ship in active_ships:
		var offset: Vector3 = ship.global_position - global_position
		var distance: float = offset.length()

		if distance <= 0.0001:
			continue

		var shell_thickness: float = maxf(_exclusion_radius_m - _planet_radius_m, 0.001)
		var depth_ratio: float = 1.0 - clampf(
			(distance - _planet_radius_m) / shell_thickness,
			0.0,
			1.0
		)

		if (
			atmosphere_damage_per_second > 0.0
			and depth_ratio >= atmosphere_damage_depth_start
		):
			var damage_t: float = inverse_lerp(
				atmosphere_damage_depth_start,
				1.0,
				depth_ratio
			)
			var damage_this_frame: float = (
				atmosphere_damage_per_second * lerpf(0.25, 1.0, damage_t) * delta
			)
			if damage_this_frame > 0.0:
				ship.receive_damage(damage_this_frame, self)
