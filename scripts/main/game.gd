extends Node2D

func _ready() -> void:
	if SaveManager.has_save():
		if not SaveManager.load_game():
			push_error("Existing save could not be loaded.")
			return
	else:
		WorldState.new_world(randi())
		SaveManager.save_game()

func _process(delta: float) -> void:
	WorldState.tick(delta)
