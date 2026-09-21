class_name ProductionRecipeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var inputs: Array[RecipeIngredientData] = []
@export var output: GoodData
@export var output_quantity: float = 1.0
@export var production_time: float = 60.0
