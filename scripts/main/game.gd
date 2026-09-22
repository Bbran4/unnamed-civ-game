extends Node2D

func _ready() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		WorldState.new_world(randi())
		SaveManager.save_game()

func _process(delta: float) -> void:
	WorldState.tick(delta)
