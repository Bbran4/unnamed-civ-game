class_name StationTypeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var population_multiplier: float = 1.0
@export var industries: Array[String] = []
@export var resource_imports: Array[ResourceData] = []
@export var resource_exports: Array[ResourceData] = []
@export var good_imports: Array[GoodData] = []
@export var good_exports: Array[GoodData] = []
@export var production_recipes: Array[ProductionRecipeData] = []
