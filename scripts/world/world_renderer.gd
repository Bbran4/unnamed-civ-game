class_name WorldRenderer
extends Node2D

const TILE_SIZE := 12.0
const MAP_ORIGIN := Vector2(256.0, 12.0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var world_data: Dictionary = WorldState.world_data
	var width := int(world_data.get("width", 0))
	var height := int(world_data.get("height", 0))
	var terrain: Array = world_data.get("terrain", [])

	if width <= 0 or height <= 0 or terrain.size() != width * height:
		return

	for y in range(height):
		for x in range(width):
			var index := y * width + x
			var terrain_type := int(terrain[index])
			var rect := Rect2(
				MAP_ORIGIN + Vector2(x, y) * TILE_SIZE,
				Vector2.ONE * TILE_SIZE
			)
			draw_rect(rect, _terrain_color(terrain_type))

	draw_string(
		ThemeDB.fallback_font,
		MAP_ORIGIN + Vector2(0.0, height * TILE_SIZE + 24.0),
		"Seed: %d" % int(world_data.get("seed", 0)),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18
	)

func _terrain_color(terrain_type: int) -> Color:
	match terrain_type:
		WorldGenerator.TERRAIN_WATER:
			return Color("4f7fa8")
		WorldGenerator.TERRAIN_PLAINS:
			return Color("b5a66a")
		WorldGenerator.TERRAIN_FOREST:
			return Color("5f7d4b")
		WorldGenerator.TERRAIN_MOUNTAIN:
			return Color("777777")
		WorldGenerator.TERRAIN_DESERT:
			return Color("c99d5b")
		_:
			return Color("ff00ff")
