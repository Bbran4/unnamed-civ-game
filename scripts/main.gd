extends Node3D

## Main prototype scene setup.
##
## The main scene currently uses ShipSpawner to create one test enemy.
## This is temporary prototype setup, not the final encounter system.

const STARTER_FIGHTER_DATA: ShipData = preload("res://data/ships/starter_fighter.tres")
const STARTER_LASER_DATA: WeaponData = preload("res://data/weapons/starter_laser.tres")
const ENEMY_CONTROLLER_SCRIPT: Script = preload("res://scripts/enemies/enemy_ship_controller.gd")

@export_category("Prototype Rewards")
@export var enemy_destruction_reward: int = 100

var prototype_credits: int = 0

@onready var player_ship: Ship = $PlayerShip
@onready var ship_spawner: ShipSpawner = $ShipSpawner
@onready var asteron: Planet = $Asteron
@onready var asteron_surface_streamer: PlanetSurfaceStreamer = $Asteron/PlanetSurfaceStreamer


func _physics_process(_delta: float) -> void:
	if player_ship != null and asteron != null:
		asteron.update_ship_environment(player_ship)


func _ready() -> void:
	if asteron_surface_streamer != null:
		asteron_surface_streamer.set_target_ship(player_ship)

	var player_weapon_left: Weapon = player_ship.equip_weapon(STARTER_LASER_DATA, 0)
	var player_weapon_right: Weapon = player_ship.equip_weapon(STARTER_LASER_DATA, 1)

	if player_weapon_left == null or player_weapon_right == null:
		push_error("Failed to equip both starter lasers to player ship.")

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

	enemy.destroyed.connect(_on_enemy_destroyed)

	var enemy_light: OmniLight3D = OmniLight3D.new()
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


func _on_enemy_destroyed(source: Node) -> void:
	if source != player_ship:
		return

	prototype_credits += maxi(enemy_destruction_reward, 0)
