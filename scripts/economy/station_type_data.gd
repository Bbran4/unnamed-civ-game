class_name StationTypeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var population_multiplier: float = 1.0
@export var industries: Array[String] = []
@export var imports: Array[GoodData] = []
@export var exports: Array[GoodData] = []
