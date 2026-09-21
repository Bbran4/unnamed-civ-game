class_name PlanetTypeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var min_radius: float = 0.0
@export var max_radius: float = 0.0
@export var min_temperature: float = 0.0
@export var max_temperature: float = 0.0
@export var atmosphere: String = ""
@export var gravity_multiplier: float = 1.0
@export var available_resources: Array[ResourceData] = []
