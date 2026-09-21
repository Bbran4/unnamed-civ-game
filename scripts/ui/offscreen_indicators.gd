extends CanvasLayer

@export var edge_margin: float = 48.0

@onready var player_ship: Node2D = get_tree().get_first_node_in_group("player_ship") as Node2D
@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var station_indicator: Control = $StationIndicator
@onready var enemy_indicators: Array[Control] = [
	$EnemyIndicators/EnemyIndicator1,
	$EnemyIndicators/EnemyIndicator2,
	$EnemyIndicators/EnemyIndicator3,
	$EnemyIndicators/EnemyIndicator4,
	$EnemyIndicators/EnemyIndicator5,
	$EnemyIndicators/EnemyIndicator6,
	$EnemyIndicators/EnemyIndicator7,
	$EnemyIndicators/EnemyIndicator8
]

func _process(_delta: float) -> void:
	if not is_instance_valid(player_ship):
		player_ship = get_tree().get_first_node_in_group("player_ship") as Node2D
	if not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
	if not is_instance_valid(player_ship) or not is_instance_valid(camera):
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var viewport_center: Vector2 = viewport_size * 0.5
	var screen_rect: Rect2 = Rect2(Vector2.ZERO, viewport_size)
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy_ship")

	for indicator_index: int in enemy_indicators.size():
		var indicator: Control = enemy_indicators[indicator_index]
		if indicator_index >= enemies.size():
			indicator.visible = false
			continue

		var enemy: Node2D = enemies[indicator_index] as Node2D
		_update_indicator(indicator, enemy.global_position, screen_rect, viewport_center, Color(1.0, 0.25, 0.2, 1.0))

	var stations: Array[Node] = get_tree().get_nodes_in_group("space_station")
	if stations.is_empty():
		station_indicator.visible = false
		return

	var nearest_station: Node2D = _find_nearest_station(stations)
	_update_indicator(station_indicator, nearest_station.global_position, screen_rect, viewport_center, Color(0.2, 0.8, 1.0, 1.0))

func _find_nearest_station(stations: Array[Node]) -> Node2D:
	var nearest_station: Node2D = stations[0] as Node2D
	var nearest_distance: float = player_ship.global_position.distance_squared_to(nearest_station.global_position)

	for station_node: Node in stations:
		var station: Node2D = station_node as Node2D
		var distance: float = player_ship.global_position.distance_squared_to(station.global_position)
		if distance < nearest_distance:
			nearest_station = station
			nearest_distance = distance

	return nearest_station

func _update_indicator(indicator: Control, world_position: Vector2, screen_rect: Rect2, viewport_center: Vector2, indicator_color: Color) -> void:
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * world_position
	var direction: Vector2 = screen_position - viewport_center
	var is_offscreen: bool = not screen_rect.grow(-edge_margin).has_point(screen_position)

	indicator.visible = is_offscreen
	if not is_offscreen:
		return

	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT

	var half_size: Vector2 = viewport_center - Vector2(edge_margin, edge_margin)
	var scale_factor: float = minf(absf(half_size.x / direction.x) if direction.x != 0.0 else INF, absf(half_size.y / direction.y) if direction.y != 0.0 else INF)
	var clamped_position: Vector2 = viewport_center + direction * scale_factor
	indicator.position = clamped_position - indicator.size * 0.5
	indicator.rotation = direction.angle() + PI * 0.5
	indicator.modulate = indicator_color
