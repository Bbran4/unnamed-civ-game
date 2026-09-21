extends Control

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var max_shield: float = 50.0
@export var current_shield: float = 50.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var shield_bar: ProgressBar = $ShieldBar

func _ready() -> void:
	_update_bars()

func set_values(
	new_current_health: float,
	new_max_health: float,
	new_current_shield: float,
	new_max_shield: float
) -> void:
	current_health = new_current_health
	max_health = new_max_health
	current_shield = new_current_shield
	max_shield = new_max_shield
	_update_bars()

func _update_bars() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	shield_bar.max_value = max_shield
	shield_bar.value = current_shield
