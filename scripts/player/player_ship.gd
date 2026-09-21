extends CharacterBody2D

enum ControlStyle {
    ROTATION_KEYS,
    MOUSE_AIM
}

@export var forward_acceleration: float = 600.0
@export var reverse_acceleration: float = 350.0
@export var turn_speed: float = 3.5
@export var momentum_decay_time: float = 1.0
@export var max_speed: float = 550.0
@export var boost_max_speed: float = 800.0
@export var boost_acceleration: float = 850.0
@export var max_hull: float = 100.0
@export var max_shield: float = 50.0
@export var shield_regen_rate: float = 15.0
@export var shield_regen_delay: float = 2.0
@export var primary_fire_cooldown: float = 0.18
@export var warp_enemy_detection_range: float = 1400.0
@export var projectile_scene: PackedScene

var current_hull: float = 100.0
var current_shield: float = 50.0
var shield_regen_remaining: float = 0.0
var fire_cooldown_remaining: float = 0.0
var control_style: ControlStyle = ControlStyle.ROTATION_KEYS

@onready var weapon_muzzle: Marker2D = $WeaponMuzzle
@onready var camera: Camera2D = $Camera2D
@onready var status_bars: Control = $PlayerStatusBars/Bars

func _ready() -> void:
    current_hull = max_hull
    current_shield = max_shield
    control_style = WorldState.control_style as ControlStyle

    if WorldState.returning_from_station:
        global_position = WorldState.station_exit_position
        WorldState.returning_from_station = false
    else:
        global_position = WorldState.system_entry_position

    _update_status_bars()

func _physics_process(delta: float) -> void:
    _shield_regeneration(delta)

    if WorldState.map_open:
        velocity = Vector2.ZERO
        return

    var forward_direction: Vector2 = Vector2.RIGHT.rotated(rotation)
    var boost_active: bool = Input.is_action_pressed("boost")
    var current_max_speed: float = max_speed

    if control_style == ControlStyle.ROTATION_KEYS:
        boost_active = boost_active and Input.is_action_pressed("move_up")
        var turn_input: float = Input.get_axis("move_left", "move_right")
        if turn_input != 0.0:
            rotation += turn_input * turn_speed * delta
    else:
        var mouse_position: Vector2 = get_global_mouse_position()
        var direction_to_mouse: Vector2 = mouse_position - global_position
        if direction_to_mouse.length_squared() > 0.0:
            rotation = direction_to_mouse.angle()

        var strafe_input: float = Input.get_axis("move_left", "move_right")
        if strafe_input != 0.0:
            var right_direction: Vector2 = Vector2.DOWN.rotated(rotation)
            velocity += right_direction * strafe_input * forward_acceleration * delta

    forward_direction = Vector2.RIGHT.rotated(rotation)

    if boost_active:
        current_max_speed = boost_max_speed
        velocity += forward_direction * boost_acceleration * delta

    if Input.is_action_pressed("move_up"):
        velocity += forward_direction * forward_acceleration * delta

    if Input.is_action_pressed("move_down"):
        velocity -= forward_direction * reverse_acceleration * delta
    elif not Input.is_action_pressed("move_up"):
        var momentum_decay_acceleration: float = max_speed / momentum_decay_time
        velocity = velocity.move_toward(Vector2.ZERO, momentum_decay_acceleration * delta)

    if velocity.length() > current_max_speed:
        velocity = velocity.normalized() * current_max_speed

    move_and_slide()
    camera.update_speed_zoom(boost_active, delta)

    fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
    if Input.is_action_pressed("primary_fire"):
        _fire_primary()

func is_in_danger_zone() -> bool:
    if shield_regen_remaining > 0.0:
        return true

    for enemy_node: Node in get_tree().get_nodes_in_group("enemy_ship"):
        var enemy_ship: Node2D = enemy_node as Node2D
        if enemy_ship == null:
            continue

        var distance_to_enemy: float = global_position.distance_to(enemy_ship.global_position)
        if distance_to_enemy <= warp_enemy_detection_range:
            return true

    return false

func set_control_style(new_control_style: ControlStyle) -> void:
    control_style = new_control_style
    WorldState.control_style = new_control_style as int

func _fire_primary() -> void:
    if fire_cooldown_remaining > 0.0 or projectile_scene == null:
        return

    var projectile_instance: Node = projectile_scene.instantiate()
    if projectile_instance is Node2D:
        var projectile_2d: Node2D = projectile_instance
        projectile_2d.global_position = weapon_muzzle.global_position
        projectile_2d.global_rotation = global_rotation
        projectile_2d.set("owner_group", "player_projectile")
        get_tree().current_scene.add_child(projectile_2d)
        fire_cooldown_remaining = primary_fire_cooldown

func take_damage(damage_amount: float) -> void:
    shield_regen_remaining = shield_regen_delay
    var remaining_damage: float = damage_amount

    if current_shield > 0.0:
        var shield_damage: float = minf(current_shield, remaining_damage)
        current_shield -= shield_damage
        remaining_damage -= shield_damage

    if remaining_damage > 0.0:
        current_hull = maxf(0.0, current_hull - remaining_damage)

    _update_status_bars()
    camera.shake(0.06, 2.0)

    if current_hull <= 0.0:
        queue_free()

func _shield_regeneration(delta: float) -> void:
    if shield_regen_remaining > 0.0:
        shield_regen_remaining = maxf(0.0, shield_regen_remaining - delta)
        return

    if current_shield >= max_shield:
        return

    current_shield = minf(max_shield, current_shield + shield_regen_rate * delta)
    _update_status_bars()

func _update_status_bars() -> void:
    status_bars.set_values(current_hull, max_hull, current_shield, max_shield)
