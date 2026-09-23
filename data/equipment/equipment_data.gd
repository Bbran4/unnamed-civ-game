class_name EquipmentData
extends Resource

## Static definition for installable ship equipment.
##
## Equipment mass contributes to the runtime ship's total mass.
## More specialised equipment types, such as weapons, can inherit from this
## resource later.

@export var id: StringName = &"equipment"
@export var display_name: String = "Equipment"
@export var mass_kg: float = 0.0
