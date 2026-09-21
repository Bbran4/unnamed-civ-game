class_name GeneratedMoonVisual
extends Node2D

@export var moon_data: GeneratedMoonData

const BASE_SCENE_RADIUS: float = 55.0
const MIN_VISUAL_RADIUS: float = 35.0
const MAX_VISUAL_RADIUS: float = 90.0
const MIN_MOON_RADIUS: float = 500.0
const MAX_MOON_RADIUS: float = 12000.0

@onready var moon_body: Polygon2D = $MoonBody
@onready var moon_label: Label = $MoonLabel

func apply_data(data: GeneratedMoonData) -> void:
    moon_data = data
    if moon_data == null:
        return

    var visual_radius: float = remap(
        clampf(moon_data.radius, MIN_MOON_RADIUS, MAX_MOON_RADIUS),
        MIN_MOON_RADIUS,
        MAX_MOON_RADIUS,
        MIN_VISUAL_RADIUS,
        MAX_VISUAL_RADIUS
    )
    var visual_scale: float = visual_radius / BASE_SCENE_RADIUS
    scale = Vector2.ONE * visual_scale

    moon_label.text = moon_data.display_name
    moon_label.scale = Vector2.ONE / visual_scale
    moon_label.position = Vector2(-55.0, visual_radius + 8.0)
