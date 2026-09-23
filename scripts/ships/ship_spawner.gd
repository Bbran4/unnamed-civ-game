class_name ShipSpawner
extends Node3D

## Reusable ship spawning helper.
##
## ShipSpawner creates runtime Ship instances from the generic ship scene.
## Static ship design comes from ShipData, while an optional controller script
## determines who pilots the spawned vessel.
##
## Controllers are attached before the ship enters the scene tree so Ship can
## discover and initialise them normally.

@export_category("Ship Scene")
@export var ship_scene: PackedScene = preload("res://scenes/ships/ship.tscn")


## Spawn a ship using the supplied ShipData and optional controller.
##
## The returned Ship is ready for gameplay once it has entered the scene tree.
## The world_transform is expressed in global space.
func spawn_ship(
	parent: Node3D,
	ship_data: ShipData,
	world_transform: Transform3D = Transform3D.IDENTITY,
	controller_script: Script = null
) -> Ship:
	if parent == null:
		push_error("ShipSpawner requires a valid Node3D parent.")
		return null

	if ship_data == null:
		push_error("ShipSpawner requires ShipData.")
		return null

	if ship_scene == null:
		push_error("ShipSpawner has no ship scene assigned.")
		return null

	var instance: Node = ship_scene.instantiate()
	var ship: Ship = instance as Ship

	if ship == null:
		push_error("ShipSpawner scene must instantiate a Ship.")
		instance.queue_free()
		return null

	ship.ship_data = ship_data

	if controller_script != null:
		var controller_node: Node = Node.new()
		controller_node.set_script(controller_script)

		var controller: ShipController = controller_node as ShipController

		if controller == null:
			push_error("ShipSpawner controller script must inherit from ShipController.")
			controller_node.free()
			instance.queue_free()
			return null

		ship.add_child(controller_node)

	parent.add_child(ship)
	ship.global_transform = world_transform

	return ship
