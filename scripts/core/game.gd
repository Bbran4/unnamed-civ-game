extends Node

## Global game foundation.
## Systems should be added here only when they genuinely need global lifetime/state.
##
## Milestone 0 deliberately keeps this script small. Avoid turning it into a
## catch-all GameManager.

func _ready() -> void:
	print("Unnamed Space Game initialized.")
