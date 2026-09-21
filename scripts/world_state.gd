extends Node

## Shared game state used by systems that persist between scenes.
var credits: int = 500
var current_ship_id: String = "starter_shuttle"
var inventory: Dictionary = {}
var owned_ships: Array[String] = ["starter_shuttle"]
var active_missions: Array[String] = []
var completed_missions: Array[String] = []
var faction_reputation: Dictionary = {}

func reset_to_defaults() -> void:
	credits = 500
	current_ship_id = "starter_shuttle"
	inventory = {}
	owned_ships = ["starter_shuttle"]
	active_missions = []
	completed_missions = []
	faction_reputation = {}
