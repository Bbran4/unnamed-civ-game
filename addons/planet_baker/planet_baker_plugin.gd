@tool
extends EditorPlugin

## Adds the Planet Surface Baker dock to the editor.
##
## The dock lets a PlanetData resource be baked into an equirectangular
## surface texture without leaving the editor. Baking logic lives entirely in
## PlanetTextureBaker; this plugin only registers the dock.

const DOCK_SCENE: PackedScene = preload("res://addons/planet_baker/planet_baker_dock.tscn")

var dock: Control


func _enter_tree() -> void:
	dock = DOCK_SCENE.instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree() -> void:
	if dock == null:
		return

	remove_control_from_docks(dock)
	dock.queue_free()
	dock = null
