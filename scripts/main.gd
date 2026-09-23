extends Node3D

## Main prototype scene setup.
##
## The main scene currently uses ShipSpawner to create one test enemy.
## This is temporary prototype setup, not the final encounter system.

const STARTER_FIGHTER_DATA: ShipData = preload("res://data/ships/starter_fighter.tres")
const ENEMY_CONTROLLER_SCRIPT: Script = preload("res://scripts/enemies/enemy_ship_controller.gd")

@onready var player_ship: Ship = $PlayerShip
@onready var ship_spawner: ShipSpawner = $ShipSpawner


func _ready() -> void:
	var enemy_transform := Transform3D(
		Basis.IDENTITY,
		Vector3(0.0, 0.0, -120.0)
	)

	var enemy: Ship = ship_spawner.spawn_ship(
		self,
		STARTER_FIGHTER_DATA,
		enemy_transform,
		ENEMY_CONTROLLER_SCRIPT
	)

	if enemy == null:
		push_error("Failed to spawn prototype enemy.")
		return

	for child: Node in enemy.get_children():
		if child is EnemyShipController:
			child.set_target(player_ship)
			break
