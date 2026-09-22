extends Node
class_name SaveManager

const SAVE_PATH := "user://civilization_save.json"

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save file for writing.")
		return false

	file.store_string(JSON.stringify(WorldState.get_save_data(), "\t"))
	file.close()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Save file contains invalid JSON.")
		return false

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("Save file root must be a dictionary.")
		return false

	WorldState.load_save_data(json.data)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
