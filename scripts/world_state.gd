extends Node

## Shared game state used by systems that persist between scenes.
var credits: int = 500
var current_ship_id: String = "starter_shuttle"
var inventory: Dictionary = {}
var owned_ships: Array[String] = ["starter_shuttle"]
var active_missions: Array[String] = []
var completed_missions: Array[String] = []
var faction_reputation: Dictionary = {}
var control_style: int = 0
var returning_from_station: bool = false
var station_exit_position: Vector2 = Vector2(950.0, 120.0)
var current_system_scene: String = "res://scenes/world/systems/asterion.tscn"
var current_system_id: String = "asterion"

func reset_to_defaults() -> void:
    credits = 500
    current_ship_id = "starter_shuttle"
    inventory = {}
    owned_ships = ["starter_shuttle"]
    active_missions = []
    completed_missions = []
    faction_reputation = {}
    control_style = 0
    returning_from_station = false
    station_exit_position = Vector2(950.0, 120.0)
    current_system_scene = "res://scenes/world/systems/asterion.tscn"
    current_system_id = "asterion"
