class_name GeneratedStarVisual
extends Node2D

@export var star_data: StarData

const BASE_SCENE_RADIUS: float = 220.0
const MIN_VISUAL_RADIUS: float = 220.0
const MAX_VISUAL_RADIUS: float = 700.0
const MIN_STAR_RADIUS: float = 250.0
const MAX_STAR_RADIUS: float = 1700.0

@onready var star_body: Polygon2D = $StarBody
@onready var corona: Polygon2D = $Corona
@onready var star_label: Label = $StarLabel

func apply_data(data: StarData, generated_radius: float) -> void:
    star_data = data
    if star_data == null:
        return

    var visual_radius: float = remap(
        clampf(generated_radius, MIN_STAR_RADIUS, MAX_STAR_RADIUS),
        MIN_STAR_RADIUS,
        MAX_STAR_RADIUS,
        MIN_VISUAL_RADIUS,
        MAX_VISUAL_RADIUS
    )
    visual_radius *= 5.0
    var visual_scale: float = visual_radius / BASE_SCENE_RADIUS
    scale = Vector2.ONE * visual_scale

    star_body.color = star_data.color
    corona.color = Color(star_data.color.r, star_data.color.g, star_data.color.b, 0.16)

    star_label.text = star_data.display_name
    star_label.scale = Vector2.ONE / visual_scale
    star_label.position = Vector2(-140.0, visual_radius + 25.0)
