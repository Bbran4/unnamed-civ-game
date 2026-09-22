class_name FactionData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var faction_category: String = "civilian"
@export var preferred_station_types: Array[StationTypeData] = []
@export var preferred_goods: Array[GoodData] = []
@export var relations: Dictionary[String, int] = {}

func get_relation_to(other_faction_id: String) -> int:
	return relations.get(other_faction_id, 0)

func is_hostile_to(other_faction_id: String) -> bool:
	return get_relation_to(other_faction_id) <= -50

func is_friendly_to(other_faction_id: String) -> bool:
	return get_relation_to(other_faction_id) >= 50
