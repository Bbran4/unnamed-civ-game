class_name AsteroidField
extends Node2D

const ASTEROID_SCENE: PackedScene = preload("res://scenes/asteroids/asteroid.tscn")

@export var asteroid_count: int = 80
@export var inner_radius: float = 9000.0
@export var outer_radius: float = 11500.0
@export var orbital_period: float = 180.0
@export var random_seed: int = 1
@export var orbit_time_scale: float = 0.05

var asteroid_instances: Array[Node2D] = []
var asteroid_angles: Array[float] = []
var asteroid_distances: Array[float] = []
var asteroid_speeds: Array[float] = []
var simulation_time: float = 0.0

func _ready() -> void:
    _generate_field()

func _process(delta: float) -> void:
    simulation_time += delta * orbit_time_scale
    _update_field()

func _generate_field() -> void:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = random_seed

    for index: int in range(asteroid_count):
        var asteroid: Node2D = ASTEROID_SCENE.instantiate() as Node2D
        if asteroid == null:
            continue

        add_child(asteroid)

        var distance: float = rng.randf_range(inner_radius, outer_radius)
        var angle: float = rng.randf_range(0.0, TAU)
        var period_variation: float = rng.randf_range(0.75, 1.25)
        var speed: float = TAU / maxf(orbital_period * period_variation, 1.0)

        asteroid_instances.append(asteroid)
        asteroid_angles.append(angle)
        asteroid_distances.append(distance)
        asteroid_speeds.append(speed)

        var scale_value: float = rng.randf_range(0.45, 1.8)
        asteroid.scale = Vector2.ONE * scale_value

func _update_field() -> void:
    for index: int in range(asteroid_instances.size()):
        var asteroid: Node2D = asteroid_instances[index]
        var angle: float = asteroid_angles[index] + asteroid_speeds[index] * simulation_time
        var distance: float = asteroid_distances[index]
        asteroid.position = Vector2(cos(angle), sin(angle)) * distance
