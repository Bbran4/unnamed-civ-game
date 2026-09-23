class_name ProjectileData
extends Resource

## Static definition for a projectile.
##
## ProjectileData contains the design inputs used by a runtime Projectile.
## Changing state such as remaining lifetime, position, velocity and target
## belongs to the Projectile instance.

@export_category("Identity")
@export var id: StringName = &"projectile"
@export var display_name: String = "Projectile"

@export_category("Impact")
## Damage applied when the projectile successfully hits a valid target.
@export var damage: float = 10.0

@export_category("Movement")
## Projectile travel speed in metres per second.
@export var speed_mps: float = 500.0

## Maximum lifetime in seconds.
## The runtime projectile is destroyed when this expires.
@export var lifetime: float = 5.0

## Collision radius in metres.
@export var radius: float = 0.1

@export_category("Homing")
## Whether the projectile can steer toward a target.
@export var homing: bool = false

## Maximum homing turn rate in radians per second.
## Ignored when homing is disabled.
@export var turn_rate_rad_s: float = 0.0

@export_category("Presentation")
## Optional scene used to visually represent the projectile.
## The runtime Projectile handles movement and collision separately.
@export var visual_scene: PackedScene
