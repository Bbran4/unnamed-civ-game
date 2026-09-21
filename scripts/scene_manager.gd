extends Node

## Centralized scene transition helper.
func change_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene does not exist: %s" % scene_path)
		return

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to change scene to %s. Error: %s" % [scene_path, error])

func reload_current_scene() -> void:
	get_tree().reload_current_scene()
