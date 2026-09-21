class_name FactionData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var preferred_station_types: Array[StationTypeData] = []
@export var preferred_goods: Array[GoodData] = []
