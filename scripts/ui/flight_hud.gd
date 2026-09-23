extends CanvasLayer

## Combat and flight HUD.
##
## This HUD reads runtime state from the player's Ship and its TargetingSystem.
## It deliberately does not implement target locking or target selection.
## Higher-level gameplay systems can assign a target and the HUD will reflect it.
##
## The prototype reward display reads prototype_credits from the parent Main node.
## The full player credit system belongs to a later progression milestone.

@export var ship_path: NodePath
@export var reward_source_path: NodePath = NodePath("..")

var ship: Ship
var targeting_system: TargetingSystem
var reward_source: Node
var displayed_credits: int = 0
var reward_message_timer: float = 0.0

@onready var speed_label: Label = $PlayerPanel/MarginContainer/VBoxContainer/Speed
@onready var throttle_label: Label = $PlayerPanel/MarginContainer/VBoxContainer/Throttle
@onready var status_label: Label = $PlayerPanel/MarginContainer/VBoxContainer/Status
@onready var hull_bar: ProgressBar = $PlayerPanel/MarginContainer/VBoxContainer/HullBar
@onready var shield_bar: ProgressBar = $PlayerPanel/MarginContainer/VBoxContainer/ShieldBar
@onready var energy_bar: ProgressBar = $PlayerPanel/MarginContainer/VBoxContainer/EnergyBar
@onready var credits_label: Label = $PlayerPanel/MarginContainer/VBoxContainer/Credits
@onready var target_name_label: Label = $TargetPanel/MarginContainer/VBoxContainer/TargetName
@onready var target_lock_label: Label = $TargetPanel/MarginContainer/VBoxContainer/TargetLock
@onready var target_distance_label: Label = $TargetPanel/MarginContainer/VBoxContainer/TargetDistance
@onready var target_hull_bar: ProgressBar = $TargetPanel/MarginContainer/VBoxContainer/TargetHullBar
@onready var target_shield_bar: ProgressBar = $TargetPanel/MarginContainer/VBoxContainer/TargetShieldBar
@onready var weapon_name_label: Label = $WeaponPanel/MarginContainer/VBoxContainer/WeaponName
@onready var weapon_state_label: Label = $WeaponPanel/MarginContainer/VBoxContainer/WeaponState
@onready var reticle_label: Label = $Reticle
@onready var help_label: Label = $Help


func _ready() -> void:
	ship = get_node_or_null(ship_path) as Ship
	reward_source = get_node_or_null(reward_source_path)

	if ship != null:
		targeting_system = ship.get_node_or_null("TargetingSystem") as TargetingSystem

	help_label.text = "W/S Throttle  |  Mouse Pitch/Yaw  |  Q/E Roll  |  A/D Strafe  |  Shift Boost  |  Space Brake  |  LMB Fire  |  T Target/Cycle  |  Esc Release Mouse"
	reticle_label.text = "+"
	_reset_target_display()
	_update_reward_display(0.0)


func _process(delta: float) -> void:
	if ship == null:
		return

	_update_player_display()
	_update_target_display()
	_update_weapon_display()
	_update_reward_display(delta)


func _update_player_display() -> void:
	speed_label.text = "SPEED  %03d m/s" % int(ship.get_speed())
	throttle_label.text = "THROTTLE  %03d%%" % int(ship.get_throttle_percent() * 100.0)
	status_label.text = "BOOST  ACTIVE" if ship.boost_active else "FLIGHT  CRUISE"

	hull_bar.value = ship.get_hull_fraction() * 100.0
	shield_bar.value = ship.get_shield_fraction() * 100.0
	energy_bar.value = ship.get_energy_fraction() * 100.0


func _update_reward_display(delta: float) -> void:
	if reward_source == null:
		return

	var reward_value: Variant = reward_source.get("prototype_credits")

	if reward_value == null:
		return

	var current_credits: int = int(reward_value)

	if current_credits > displayed_credits:
		var reward_amount: int = current_credits - displayed_credits
		reward_message_timer = 2.5
		$Reward.text = "REWARD  +%d CREDITS" % reward_amount

	displayed_credits = current_credits
	credits_label.text = "CREDITS  %d" % displayed_credits

	if reward_message_timer > 0.0:
		reward_message_timer = maxf(reward_message_timer - delta, 0.0)

		if reward_message_timer <= 0.0:
			$Reward.text = ""


func _update_target_display() -> void:
	if targeting_system == null:
		_reset_target_display()
		return

	var target_node: Node3D = targeting_system.get_target()

	if target_node == null:
		_reset_target_display()
		return

	var target_ship: Ship = target_node as Ship

	if target_ship == null:
		target_lock_label.text = "LOCK  ACTIVE"
		target_name_label.text = "TARGET  OBJECT"
		target_distance_label.text = "DISTANCE  %03d m" % int(targeting_system.get_target_distance())
		target_hull_bar.value = 0.0
		target_shield_bar.value = 0.0
		return

	target_lock_label.text = "LOCK  ACTIVE"
	target_name_label.text = "TARGET  %s" % target_ship.name
	target_distance_label.text = "DISTANCE  %03d m" % int(targeting_system.get_target_distance())
	target_hull_bar.value = target_ship.get_hull_fraction() * 100.0
	target_shield_bar.value = target_ship.get_shield_fraction() * 100.0


func _update_weapon_display() -> void:
	var weapon: Weapon = ship.get_weapon(0)

	if weapon == null or weapon.weapon_data == null:
		weapon_name_label.text = "WEAPON  NONE"
		weapon_state_label.text = "NO WEAPON EQUIPPED"
		return

	weapon_name_label.text = "WEAPON  %s" % weapon.weapon_data.display_name

	if weapon.get_cooldown_remaining() > 0.0:
		weapon_state_label.text = "COOLDOWN  %.2fs" % weapon.get_cooldown_remaining()
	elif ship.current_energy < maxf(weapon.weapon_data.energy_cost, 0.0):
		weapon_state_label.text = "LOW ENERGY"
	else:
		weapon_state_label.text = "READY"


func _reset_target_display() -> void:
	target_lock_label.text = "LOCK  NONE"
	target_name_label.text = "TARGET  NONE"
	target_distance_label.text = "DISTANCE  ---"
	target_hull_bar.value = 0.0
	target_shield_bar.value = 0.0
