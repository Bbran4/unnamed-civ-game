extends Node3D

## Main prototype scene setup.
##
## The main scene currently uses ShipSpawner to create one test enemy.
## This is temporary prototype setup, not the final encounter system.

const STARTER_FIGHTER_DATA: ShipData = preload("res://data/ships/starter_fighter.tres")
const STARTER_LASER_DATA: WeaponData = preload("res://data/weapons/starter_laser.tres")
const ENEMY_CONTROLLER_SCRIPT: Script = preload("res://scripts/enemies/enemy_ship_controller.gd")

@onready var player_ship: Ship = $PlayerShip
@onready var ship_spawner: ShipSpawner = $ShipSpawner


func _ready() -> void:
	var player_weapon: Weapon = player_ship.equip_weapon(STARTER_LASER_DATA, 0)

	if player_weapon == null:
		push_error("Failed to equip starter laser to player ship.")

	# Give the prototype enemy the same starter weapon so the AI state machine
	# can be tested in a live two-sided dogfight.

	var enemy_transform: Transform3D = Transform3D(
		Basis.IDENTITY,
		Vector3(12.0, 0.0, -60.0)
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

	enemy.name = "PrototypeEnemy"


	var enemy_weapon: Weapon = enemy.equip_weapon(STARTER_LASER_DATA, 0)

	if enemy_weapon == null:
		push_error("Failed to equip starter laser to prototype enemy.")

	var enemy_light := OmniLight3D.new()
	enemy_light.name = "EnemyGlow"
	enemy_light.light_color = Color(1.0, 0.12, 0.08)
	enemy_light.light_energy = 3.0
	enemy_light.omni_range = 8.0
	enemy_light.position = Vector3(0.0, 0.0, 2.2)
	enemy.add_child(enemy_light)

	for child: Node in enemy.get_children():
		if child is EnemyShipController:
			child.set_target(player_ship)
			break

	var player_targeting: TargetingSystem = player_ship.get_node_or_null("TargetingSystem") as TargetingSystem

	if player_targeting != null:
		# Temporary combat-test target assignment. This is not target-lock input.
		player_targeting.set_target(enemy)
