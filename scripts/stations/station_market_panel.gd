extends CanvasLayer

const MAX_ROWS: int = 8

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Title
@onready var close_button: Button = $Panel/CloseButton

var station: GeneratedStationData

func _ready() -> void:
	close_button.pressed.connect(close_market)
	panel.visible = false

func open_market() -> void:
	station = _get_current_station()
	if station == null or station.market == null:
		return
	_update_display()
	panel.visible = true

func close_market() -> void:
	panel.visible = false

func _process(_delta: float) -> void:
	if panel.visible and Input.is_action_just_pressed("ui_cancel"):
		close_market()

func _update_display() -> void:
	title_label.text = "%s  |  MARKET" % station.display_name
	var demand_items: Array[String] = _get_top_demand_item_ids()
	var supply_items: Array[String] = _get_top_supply_item_ids()

	for row_index: int in range(MAX_ROWS):
		var demand_label: Label = panel.get_node("Demand%d" % (row_index + 1)) as Label
		var supply_label: Label = panel.get_node("Supply%d" % (row_index + 1)) as Label
		demand_label.visible = row_index < demand_items.size()
		supply_label.visible = row_index < supply_items.size()

		if row_index < demand_items.size():
			demand_label.text = _format_market_row(demand_items[row_index], true)
		if row_index < supply_items.size():
			supply_label.text = _format_market_row(supply_items[row_index], false)

func _format_market_row(item_id: String, is_demand: bool) -> String:
	var display_name: String = _get_item_display_name(item_id)
	var quantity: float = 0.0

	if is_demand:
		quantity = float(station.market.demand.get(item_id, 0.0))
	else:
		quantity = float(station.market.supply.get(item_id, 0.0))

	var price: float = float(
		station.market.current_prices.get(
			item_id,
			float(station.market.base_values.get(item_id, 0.0))
		)
	)

	if is_demand:
		return "%-24s %7.4f /s     %6.0f cr" % [
			display_name,
			quantity,
			price
		]

	return "%-24s %7.2f units   %6.0f cr" % [
		display_name,
		quantity,
		price
	]

func _get_top_demand_item_ids() -> Array[String]:
	var item_ids: Array[String] = []
	var item_scores: Array[Dictionary] = []

	for item_id: String in station.market.demand.keys():
		var demand_value: float = float(
			station.market.demand.get(item_id, 0.0)
		)
		if demand_value <= 0.0:
			continue

		item_scores.append({
			"id": item_id,
			"score": demand_value
		})

	item_scores.sort_custom(_sort_market_scores)

	for score_entry: Dictionary in item_scores:
		if item_ids.size() >= MAX_ROWS:
			break
		item_ids.append(String(score_entry["id"]))

	return item_ids

func _get_top_supply_item_ids() -> Array[String]:
	var item_ids: Array[String] = []
	var item_scores: Array[Dictionary] = []

	for item_id: String in station.market.supply.keys():
		var supply_value: float = float(
			station.market.supply.get(item_id, 0.0)
		)
		if supply_value <= 0.0:
			continue

		item_scores.append({
			"id": item_id,
			"score": supply_value
		})

	item_scores.sort_custom(_sort_market_scores)

	for score_entry: Dictionary in item_scores:
		if item_ids.size() >= MAX_ROWS:
			break
		item_ids.append(String(score_entry["id"]))

	return item_ids

func _sort_market_scores(left: Dictionary, right: Dictionary) -> bool:
	var left_score: float = float(left.get("score", 0.0))
	var right_score: float = float(right.get("score", 0.0))
	return left_score > right_score

func _get_item_display_name(item_id: String) -> String:
	var resource_paths: Array[String] = Market.RESOURCE_PATHS
	for resource_path: String in resource_paths:
		var loaded_resource: Resource = ResourceLoader.load(resource_path)
		var resource_data: ResourceData = loaded_resource as ResourceData
		if resource_data != null and resource_data.id == item_id:
			return resource_data.display_name

	var good_paths: Array[String] = Market.GOOD_PATHS
	for good_path: String in good_paths:
		var loaded_resource: Resource = ResourceLoader.load(good_path)
		var good_data: GoodData = loaded_resource as GoodData
		if good_data != null and good_data.id == item_id:
			return good_data.display_name

	return item_id

func _get_current_station() -> GeneratedStationData:
	if WorldState.current_station_id.is_empty():
		return null

	var system: GeneratedSystemData = GalaxyState.get_system(
		WorldState.current_system_id
	)

	for candidate: GeneratedStationData in system.stations:
		if candidate.id == WorldState.current_station_id:
			return candidate

	return null
