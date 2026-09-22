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
	if station == null or station.market == null or station.station_type == null:
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
	var demand_items: Array[String] = _get_demand_item_ids()
	var supply_items: Array[String] = _get_supply_item_ids()

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
	var display_name: String = item_id
	var base_value: float = 0.0

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data != null and resource_data.id == item_id:
			display_name = resource_data.display_name
			base_value = resource_data.base_value

	for resource_data: ResourceData in station.station_type.resource_exports:
		if resource_data != null and resource_data.id == item_id:
			display_name = resource_data.display_name
			base_value = resource_data.base_value

	for good_data: GoodData in station.station_type.good_imports:
		if good_data != null and good_data.id == item_id:
			display_name = good_data.display_name
			base_value = good_data.base_value

	for good_data: GoodData in station.station_type.good_exports:
		if good_data != null and good_data.id == item_id:
			display_name = good_data.display_name
			base_value = good_data.base_value

	var quantity: float = 0.0
	if is_demand:
		quantity = float(station.market.demand.get(item_id, 0.0))
	else:
		quantity = float(station.market.supply.get(item_id, 0.0))

	var price: float = float(station.market.current_prices.get(item_id, base_value))
	return "%-24s %7.1f units   %6.0f cr" % [display_name, quantity, price]

func _get_demand_item_ids() -> Array[String]:
	var item_ids: Array[String] = []

	for resource_data: ResourceData in station.station_type.resource_imports:
		if resource_data != null and not item_ids.has(resource_data.id):
			item_ids.append(resource_data.id)

	for good_data: GoodData in station.station_type.good_imports:
		if good_data != null and not item_ids.has(good_data.id):
			item_ids.append(good_data.id)

	return item_ids

func _get_supply_item_ids() -> Array[String]:
	var item_ids: Array[String] = []

	for resource_data: ResourceData in station.station_type.resource_exports:
		if resource_data != null and not item_ids.has(resource_data.id):
			item_ids.append(resource_data.id)

	for good_data: GoodData in station.station_type.good_exports:
		if good_data != null and not item_ids.has(good_data.id):
			item_ids.append(good_data.id)

	return item_ids

func _get_current_station() -> GeneratedStationData:
	if WorldState.current_station_id.is_empty():
		return null

	var system: GeneratedSystemData = GalaxyState.get_system(WorldState.current_system_id)

	for candidate: GeneratedStationData in system.stations:
		if candidate.id == WorldState.current_station_id:
			return candidate

	return null
