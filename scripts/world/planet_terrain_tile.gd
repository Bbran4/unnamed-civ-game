class_name PlanetTerrainTile
extends Node3D

## One deterministic cube-sphere terrain tile.
##
## Tile identity is defined by planet face, tile coordinates, and generation
## settings. The tile stores no authored world data, so it can be regenerated
## whenever the player returns to the same planetary region.

var planet: Planet
var face: int = 0
var tile_x: int = 0
var tile_y: int = 0
var resolution: int = 17
var angular_size_degrees: float = 12.0
var terrain_height_m: float = 8.0
var terrain_noise: FastNoiseLite
var continent_noise: FastNoiseLite

var mesh_instance: MeshInstance3D
var collision_body: StaticBody3D
var collision_shape: CollisionShape3D


func setup(
	new_planet: Planet,
	new_face: int,
	new_tile_x: int,
	new_tile_y: int,
	new_resolution: int,
	new_angular_size_degrees: float,
	new_terrain_height_m: float,
	new_terrain_noise: FastNoiseLite,
	new_continent_noise: FastNoiseLite
) -> void:
	planet = new_planet
	face = new_face
	tile_x = new_tile_x
	tile_y = new_tile_y
	resolution = maxi(new_resolution, 2)
	angular_size_degrees = maxf(new_angular_size_degrees, 0.1)
	terrain_height_m = maxf(new_terrain_height_m, 0.0)
	terrain_noise = new_terrain_noise
	continent_noise = new_continent_noise

	_build_mesh()


func _build_mesh() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var tile_count: int = maxi(
		ceili(360.0 / angular_size_degrees),
		1
	)

	var tile_size_uv: float = 2.0 / float(tile_count)

	for y: int in range(resolution - 1):
		for x: int in range(resolution - 1):
			var u0: float = -1.0 + (float(tile_x) + float(x) / float(resolution - 1)) * tile_size_uv
			var u1: float = -1.0 + (float(tile_x) + float(x + 1) / float(resolution - 1)) * tile_size_uv
			var v0: float = -1.0 + (float(tile_y) + float(y) / float(resolution - 1)) * tile_size_uv
			var v1: float = -1.0 + (float(tile_y) + float(y + 1) / float(resolution - 1)) * tile_size_uv

			_add_triangle(surface_tool, u0, v0, u1, v0, u1, v1)
			_add_triangle(surface_tool, u0, v0, u1, v1, u0, v1)

	var terrain_mesh: ArrayMesh = surface_tool.commit()

	if terrain_mesh == null:
		push_error("PlanetTerrainTile failed to generate terrain mesh.")
		return

	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.mesh = terrain_mesh
	mesh_instance.material_override = _create_material()
	add_child(mesh_instance)

	collision_body = StaticBody3D.new()
	collision_body.name = "TerrainCollision"
	add_child(collision_body)

	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	collision_shape.shape = terrain_mesh.create_trimesh_shape()
	collision_body.add_child(collision_shape)


func _add_triangle(
	surface_tool: SurfaceTool,
	u0: float,
	v0: float,
	u1: float,
	v1: float,
	u2: float,
	v2: float
) -> void:
	var position_0: Vector3 = _surface_position(u0, v0)
	var position_1: Vector3 = _surface_position(u1, v1)
	var position_2: Vector3 = _surface_position(u2, v2)

	surface_tool.set_normal(position_0.normalized())
	surface_tool.set_uv(Vector2(0.0, 0.0))
	surface_tool.add_vertex(position_0)

	surface_tool.set_normal(position_1.normalized())
	surface_tool.set_uv(Vector2(1.0, 0.0))
	surface_tool.add_vertex(position_1)

	surface_tool.set_normal(position_2.normalized())
	surface_tool.set_uv(Vector2(1.0, 1.0))
	surface_tool.add_vertex(position_2)


func _surface_position(u: float, v: float) -> Vector3:
	var direction: Vector3 = _cube_to_sphere(face, u, v)
	var terrain_value: float = (terrain_noise.get_noise_3dv(direction) + 1.0) * 0.5
	var continent_value: float = (continent_noise.get_noise_3dv(direction) + 1.0) * 0.5

	var land_mask: float = smoothstep(0.46, 0.58, continent_value)
	var detail_height: float = pow(terrain_value, 1.6)
	var height_m: float = terrain_height_m * detail_height * land_mask

	var radius_m: float = maxf(planet.planet_data.radius_m, 1.0)

	return direction * (radius_m + height_m)


func _cube_to_sphere(cube_face: int, u: float, v: float) -> Vector3:
	var cube_position: Vector3

	match cube_face:
		0:
			cube_position = Vector3(1.0, v, -u)
		1:
			cube_position = Vector3(-1.0, v, u)
		2:
			cube_position = Vector3(u, 1.0, -v)
		3:
			cube_position = Vector3(u, -1.0, v)
		4:
			cube_position = Vector3(u, v, 1.0)
		_:
			cube_position = Vector3(-u, v, -1.0)

	return cube_position.normalized()


func _create_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.roughness = 0.95
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	match planet.planet_data.planet_type:
		PlanetData.PlanetType.ICE:
			material.albedo_color = Color(0.62, 0.70, 0.76, 1.0)
		PlanetData.PlanetType.DESERT:
			material.albedo_color = Color(0.62, 0.45, 0.25, 1.0)
		PlanetData.PlanetType.BARREN:
			material.albedo_color = Color(0.34, 0.33, 0.31, 1.0)
		PlanetData.PlanetType.VOLCANIC:
			material.albedo_color = Color(0.22, 0.09, 0.05, 1.0)
		PlanetData.PlanetType.OCEAN:
			material.albedo_color = Color(0.16, 0.28, 0.18, 1.0)
		_:
			material.albedo_color = Color(0.28, 0.42, 0.20, 1.0)

	return material
