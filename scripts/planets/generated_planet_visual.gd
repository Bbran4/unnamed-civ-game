class_name GeneratedPlanetVisual
extends Node2D

@export var planet_data: GeneratedPlanetData

@onready var planet_body: Polygon2D = $PlanetBody
@onready var atmosphere: Polygon2D = $Atmosphere
@onready var planet_label: Label = $PlanetLabel

func apply_data(data: GeneratedPlanetData) -> void:
    planet_data = data
    if planet_data == null:
        return

    var visual_radius: float = remap(
        clampf(planet_data.radius, 2500.0, 80000.0),
        2500.0,
        80000.0,
        90.0,
        220.0
    )
    var visual_scale: float = visual_radius / 180.0
    scale = Vector2.ONE * visual_scale

    planet_body.color = get_planet_color(planet_data.planet_type.id)
    atmosphere.color = get_atmosphere_color(planet_data.planet_type.id)

    planet_label.text = "%s\n%s" % [
        planet_data.display_name,
        planet_data.planet_type.display_name
    ]

func get_planet_color(planet_type_id: String) -> Color:
    match planet_type_id:
        "barren":
            return Color(0.38, 0.34, 0.30, 1.0)
        "frozen":
            return Color(0.60, 0.75, 0.86, 1.0)
        "habitable":
            return Color(0.20, 0.50, 0.28, 1.0)
        "desert":
            return Color(0.68, 0.48, 0.27, 1.0)
        "ocean":
            return Color(0.16, 0.38, 0.70, 1.0)
        "volcanic":
            return Color(0.55, 0.20, 0.12, 1.0)
        "gas_giant":
            return Color(0.68, 0.48, 0.30, 1.0)
        "ice_giant":
            return Color(0.30, 0.55, 0.72, 1.0)

    return Color(0.45, 0.45, 0.45, 1.0)

func get_atmosphere_color(planet_type_id: String) -> Color:
    match planet_type_id:
        "barren":
            return Color(0.45, 0.42, 0.38, 0.12)
        "frozen":
            return Color(0.65, 0.85, 1.0, 0.16)
        "habitable":
            return Color(0.35, 0.80, 0.55, 0.18)
        "desert":
            return Color(0.90, 0.65, 0.35, 0.12)
        "ocean":
            return Color(0.30, 0.60, 1.0, 0.18)
        "volcanic":
            return Color(1.0, 0.30, 0.12, 0.14)
        "gas_giant":
            return Color(0.90, 0.65, 0.40, 0.12)
        "ice_giant":
            return Color(0.40, 0.75, 1.0, 0.16)

    return Color(0.50, 0.50, 0.50, 0.12)
