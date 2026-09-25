# Unnamed Space Game

A **3D single-player space RPG inspired by Freelancer**, built in **Godot 4.x with GDScript**.

The goal is to take the accessible space-flight, trading, combat and mission structure of classic space RPGs and combine it with newer ideas: **third-person planetary gameplay, seamless space-to-atmosphere flight, explorable station and planetary locations, varied boarding, dynamic missions, reactive factions and a living local economy**.

> **Fly anywhere. Take any job. Make your own reputation.**

---

# Core Vision

The player starts as a small-time pilot with a basic ship and very little money.

From there, they can become a:

- Mercenary
- Trader
- Explorer
- Miner
- Salvager
- Smuggler
- Pirate
- Bounty hunter
- Faction operative

The game should support a strong story, but the player should also be able to ignore it and create their own career.

The universe should feel like a place that already exists rather than a sequence of mission arenas.

---

# Design Pillars

1. **Flying is the foundation.** Space combat and navigation must be fun before anything else is added.
2. **Freedom without aimlessness.** The player should always have several worthwhile things they can do.
3. **Progression changes gameplay.** Ships and equipment should unlock different approaches, not only bigger numbers.
4. **The universe reacts.** Factions, economies and encounters should respond to player actions.
5. **The player can leave the cockpit.** Stations and selected planetary locations are playable third-person spaces.
6. **Planets are gameplay spaces.** The player can fly into atmospheres, fight enemy fighters in the air, land and explore focused surface locations.
7. **Boarding matters.** Disabled ships can become opportunities rather than automatic explosions.
8. **Build vertically first.** One excellent playable system is more valuable than twenty unfinished systems.
9. **Keep it finishable.** Simulation depth should serve gameplay, not become the project.

---

# Core Gameplay Loop

```text
Leave station
	↓
Choose a job / destination / activity
	↓
Fly through space
	↓
Encounter the universe
	↓
Fight / trade / explore / salvage
	↓
Dock / land / board / interact
	↓
Receive money, reputation and information
	↓
Upgrade ship
	↓
Choose what to do next
```

A typical session might become:

```text
Accept delivery
	↓
Detect distress signal
	↓
Investigate
	↓
Fight pirates
	↓
Rescue merchant
	↓
Gain faction reputation
	↓
Complete delivery
	↓
Sell cargo
	↓
Buy new weapon
	↓
Accept bounty
	↓
Launch again
```

The entire galaxy does not need to exist for this loop to be fun.

---

# World Structure

The game uses a **hybrid world structure**.

It is not intended to be one completely seamless galaxy. Instead, the universe combines large navigable space regions with detailed stations, planetary locations and interior spaces.

```text
Galaxy
 ├── Sector
 │    ├── Star System
 │    │    ├── Planet
 │    │    ├── Orbital Station
 │    │    ├── Asteroid Field
 │    │    ├── Trade Route
 │    │    └── Hidden Location
 │    └── ...
 └── ...
```

This lets the project create detailed locations without requiring an enormous seamless world.

---

# Planetary Gameplay

Planets are not separate walking-only levels. They are **continuous gameplay spaces connected to space flight**.

The player should be able to fly toward a planet, enter its atmosphere, fight enemy fighters and other aerial threats, descend to the surface, land, leave the ship and interact with people or objects without a traditional loading-screen transition.

The game is **not** intended to reproduce every planetary activity found in No Man's Sky. Ground gameplay is focused and mission-driven. The player mainly visits the surface to find someone, investigate a location, recover an object, meet an NPC or pursue a mission objective. Mining is primarily a **space activity involving asteroid fields**, rather than underground planetary mining.

## Planetary Flight Loop

```text
Open space
    ↓
Approach planet
    ↓
Enter atmosphere
    ↓
Atmospheric flight
    ↓
Planetary dogfight / mission
    ↓
Descend
    ↓
Land
    ↓
Leave ship
    ↓
Third-person surface gameplay
    ↓
Talk / investigate / recover / find
    ↓
Return to ship
    ↓
Take off
    ↓
Return to space
```

### Atmospheric Combat

Planetary atmospheres support the same action-focused dogfighting philosophy as space combat, while adding terrain and gravity as part of the combat environment.

Examples include:
- Chasing enemy fighters into a planet's atmosphere.
- Defending a city, settlement or military installation.
- Attacking enemy aircraft during a surface war.
- Escorting friendly ships through hostile airspace.
- Pursuing a target from space down to the surface.
- Fighting over mountains, valleys, settlements and other landmarks.

A planetary battle should feel like part of the same mission rather than a separate game mode.

### Ground Gameplay

Ground environments are **focused third-person locations**, not an attempt to simulate every square kilometre of a planet.

Possible locations include:
- Spaceports
- Settlements
- Military bases
- Research facilities
- Industrial colonies
- Frontier outposts
- Crash sites
- Battlefield locations

Ground activities are primarily:
- Talk to NPCs.
- Find a person.
- Find or recover an object.
- Investigate a location.
- Receive or complete a mission objective.
- Reach restricted areas.
- Return to the ship.

### Planetary Scale and Streaming

Planets should appear as large continuous worlds from the player's perspective, while the game streams only the terrain and gameplay content required around the player's current location.

The intended technical model is:

```text
Planetary coordinates
        ↓
Floating-origin / local-coordinate system
        ↓
Terrain streaming
        ↓
Local Godot world
        ↓
Ship / character / NPC gameplay
```

The orbital planet representation can use authored/baked textures for efficient long-distance rendering. Near the player, streamed terrain provides the actual surface used for atmospheric flight and landing.

The goal is **seamless presentation**, not an unnecessarily huge simulation. Planetary detail should increase as the player approaches the surface, while distant planetary visuals remain inexpensive.

### Asteroid Mining

Mining is primarily performed in space. Asteroid fields can contain mineable resources without requiring voxel caves, tunnels or underground planetary simulation.

```text
Asteroid field
    ↓
Locate resource-bearing asteroid
    ↓
Mine with ship equipment
    ↓
Collect resources
    ↓
Return to station / sell / use
```

This keeps mining aligned with the game's space-first focus.

---
# Space Flight

Space flight is the foundation of the game.

The player controls a 3D spacecraft using an accessible **twin-stick-inspired control scheme** rather than a full flight simulator. The mouse cursor is free to move around the screen, and the ship smoothly steers toward the cursor rather than snapping directly to it.

## Controls

- Mouse aim cursor
- Pitch / yaw steering toward cursor
- Roll
- Throttle
- Boost
- Brake
- Strafe
- Target selection
- Weapon firing
- Missile firing
- Scanner
- Cruise / travel mode

The ship should have acceleration and momentum while remaining responsive enough for close combat. Cursor steering behaves like a turn-rate system: the farther the cursor moves from the centre, the stronger the requested turn, while the ship's own angular response determines how quickly it catches up.

## Flight Model

Flight characteristics are **direct gameplay values**, tuned per ship for responsiveness and feel. Hull mass and dimensions are still part of the ship definition, but they do not determine basic handling.

Each ship defines:

~~~
Maximum speed
Acceleration
Reverse speed
Reverse / brake acceleration
Strafe speed
Strafe acceleration
Flight-assist acceleration
Boost speed
Boost acceleration
Pitch turn rate
Yaw turn rate
Roll turn rate
Pitch / yaw / roll turn acceleration
~~~

This keeps flight tuning simple. A ship resource directly answers questions such as:

> How fast is this ship?
> How quickly does it accelerate?
> How quickly can it turn?
> How responsive should it feel?

Turn rates are stored in degrees per second, while turn acceleration controls how quickly the ship reaches its requested rate. The mouse cursor maps to a requested turn rate, so moving the cursor farther from the screen centre asks for a stronger turn rather than directly rotating the ship.

Mass and dimensions can still matter to cargo, equipment, collision, visuals and other future systems. They are deliberately **not** part of the current flight equation.

### Throttle and Momentum

Throttle and velocity are separate concepts.

~~~
W
↓
Increase forward throttle
↓
Ship accelerates

Release W
↓
Throttle remains
↓
Ship maintains its current cruising speed

Space
↓
Apply braking thrust
↓
Momentum decreases

S
↓
Apply reverse thrust
↓
Ship can slow down, stop and eventually move backwards
~~~

The brake therefore **kills momentum rather than simply setting throttle to zero**.

Turning and rolling do not automatically redirect existing velocity. A ship can rotate while continuing along its current trajectory.

### Boost

Boost uses its own direct gameplay values.

~~~
Boost active
		↓
Higher acceleration
		↓
Higher speed limit
~~~

Each ship can therefore be tuned independently for normal speed, boost speed and how quickly it reaches those speeds.

## Ship States

~~~
DOCKED
  ↓
LAUNCHING
  ↓
FLYING
  ↓
COMBAT
  ↓
CRUISE
  ↓
DOCKING
  ↓
DOCKED
~~~

Other states can include:

- Disabled
- Boarding
- Jumping
- Salvaging
- Destroyed

# Combat

Combat should be readable and action-focused.

The player needs to understand:

- Current target
- Target distance
- Shields
- Hull
- Missile threats
- Friendly / hostile status
- Weapon range
- Energy state

## Initial combat systems

- Energy weapons
- Projectile weapons
- Missiles
- Shields
- Hull
- Target locking
- Weapon energy
- Missile locks
- Countermeasures
- Ship destruction

## Later systems

- Subsystem targeting
- Engine damage
- Weapon damage
- Shield generators
- Cargo destruction
- Disabled ships
- Boarding opportunities

Combat should create decisions instead of becoming a simple DPS contest.

---

# Ships

Ships are modular gameplay objects.

```text
Ship
├── Hull
├── Shields
├── Power
├── Engines
├── Cargo
├── Weapons
├── Utility Modules
├── Scanner
└── Special Equipment
```

## Example Ship Classes

### Fighter
Fast and combat-focused.

### Freighter
Large cargo capacity and weaker combat capability.

### Gunship
Slow, durable and heavily armed.

### Explorer
Long range with advanced sensors.

### Utility Ship
Designed around salvage, mining, boarding or support equipment.

These are gameplay archetypes, not final restrictions.

---

# Equipment

Equipment should be modular and data-driven.

Possible categories:

- Weapons
- Shields
- Engines
- Power generators
- Cargo modules
- Scanners
- Mining lasers
- Salvage equipment
- Tractor beams
- Cloaking devices
- Countermeasures
- Boarding equipment
- Jump equipment

A module should ideally create a new possibility.

For example:

> A better scanner should reveal something the player could not previously discover, not simply provide +10% scan range.

---

# Docking and Stations

Stations are important gameplay hubs.

```text
SPACE
  ↓
DOCKING
  ↓
STATION
  ↓
INTERIOR
```

At a station the player can:

- Repair.
- Buy and sell goods.
- Upgrade equipment.
- Accept missions.
- Talk to NPCs.
- Access terminals.
- Manage reputation.
- Save.
- Leave the ship.

---

# Leaving the Ship

One of the major additions beyond classic Freelancer-style gameplay is the ability to **leave the cockpit** in third person.

This is deliberately scoped.

We are **not** trying to build a second giant open-world game.

Instead, selected locations are focused third-person environments.

## On-foot activities

- Talk to NPCs.
- Accept missions.
- Visit shops.
- Use terminals.
- Investigate locations.
- Meet faction contacts.
- Explore station interiors.
- Reach restricted areas.
- Begin boarding sequences.

Planetary locations follow the same principle, while remaining connected to the seamless planetary flight layer described above.

A planet may contain a detailed:

- Spaceport
- Mining town
- Research facility
- Military base
- Industrial colony
- Frontier settlement

rather than an entire explorable planet.

---

# Boarding

Boarding is a major differentiating system.

A disabled ship does not automatically mean:

> **BOOM.**

It can mean:

> **Opportunity.**

Possible flow:

```text
Disable target
	↓
Approach
	↓
Board
	↓
Enter ship
	↓
Resolve boarding situation
	↓
Steal / sabotage / rescue / capture
	↓
Escape
```

## Boarding approaches

### Forced Boarding
Fight through the crew.

### Stealth Boarding
Disable security systems and avoid detection.

### Negotiated Boarding
Use dialogue, reputation or intimidation.

### Emergency Boarding
Board a damaged vessel before it is destroyed.

### Rescue Boarding
Save friendly or civilian crews.

Boarding should be optional and should never become a mandatory minigame for ordinary combat.

---

# Missions

Missions provide structured reasons to fly.

## Mission Types

- Delivery
- Escort
- Bounty
- Patrol
- Salvage
- Rescue
- Investigation
- Smuggling
- Mining
- Exploration
- Assassination
- Boarding
- Story missions

Missions should be data-driven.

A mission should describe objectives, conditions, targets, rewards and consequences rather than requiring a unique script for every contract.

---

# Dynamic Missions

The universe should be capable of generating missions from its current state.

Example:

```text
Pirates attack trade route
		↓
Merchants suffer losses
		↓
Station reports increased danger
		↓
Escort missions appear
		↓
Bounty contracts appear
		↓
Pirate hideout may be discovered
		↓
Destroying hideout changes local activity
```

The important question is:

> **Why does this mission exist?**

A mission should ideally have an explanation inside the simulated world.

---

# Economy

Trading should provide a complete alternative career.

Possible commodities:

- Food
- Water
- Fuel
- Minerals
- Metals
- Electronics
- Machinery
- Medical supplies
- Luxury goods
- Illegal goods

Locations produce and consume different goods.

```text
Mining Colony
Produces:
  Ore
  Metals

Consumes:
  Food
  Medical Supplies
  Machinery

		↓

Trade Route

		↓

Industrial Station
Produces:
  Machinery
  Electronics

Consumes:
  Metals
  Fuel
```

The first economy will use simple production and consumption rules.

Dynamic shortages and larger economic simulation come later.

---

# Factions

Factions are autonomous groups with their own interests.

Possible factions:

- Governments
- Militaries
- Corporations
- Mining guilds
- Traders
- Pirates
- Smugglers
- Mercenaries
- Colonists
- Scientists
- Criminal organisations

Each faction can have:

- Territory
- Stations
- Ships
- Economy
- Reputation
- Mission types
- Allies
- Enemies
- Goals

---

# Reputation

Reputation is a major progression system.

Example:

```text
Government     +42 Friendly
Mining Guild   +71 Trusted
Pirates        -18 Hostile
Corporation    +5 Neutral
```

Reputation can affect:

- Mission availability
- Prices
- Docking permissions
- Police behaviour
- Dialogue
- Equipment
- Faction assistance
- Story branches
- Restricted locations

The player's reputation should be a consequence of what they actually do.

---

# Living Universe

NPC ships should have purposes.

They can:

- Trade
- Patrol
- Mine
- Escort
- Hunt pirates
- Flee combat
- Respond to distress calls
- Dock
- Repair
- Deliver cargo
- Become stranded
- Be destroyed

The simulation does not need to render every ship all the time.

Logical NPC state should be able to exist independently from the visible scene.

---

# Encounters

Space should contain more than enemies waiting for the player.

Possible encounters:

- Merchant convoy
- Police patrol
- Pirate ambush
- Distress signal
- Derelict ship
- Mining operation
- Smuggler rendezvous
- Military operation
- Rescue operation
- Unknown signal
- Abandoned station
- Asteroid anomaly
- Rare trader
- Faction patrol

Encounters should use the current world state where practical.

---

# Exploration

The scanner is a gameplay system.

Players can discover:

- Hidden jump points
- Derelict ships
- Secret bases
- Resource fields
- Ancient structures
- Distress signals
- Smuggling routes
- Unmarked stations
- Unknown factions
- Rare equipment
- Story clues

Exploration should reward curiosity.

---

# Story

A central story provides direction, but it should not imprison the player.

```text
Main Story
 ├── Story Missions
 ├── Faction Stories
 ├── Side Contracts
 ├── Exploration
 └── Emergent Events
```

The story introduces the setting, factions, characters and major conflicts.

The player can then spend hours doing something completely different.

---

# Progression

Progression comes from several connected systems.

## Wealth

Earn money through:

- Missions
- Trading
- Salvage
- Bounties
- Mining
- Piracy
- Exploration

## Ship

Improve through:

- New ships
- Weapons
- Modules
- Cargo capacity
- Engines
- Shields
- Utility equipment

## Reputation

Faction relationships unlock opportunities.

## Knowledge

The player gradually learns about:

- Systems
- Factions
- Trade routes
- Hidden locations
- Equipment
- Mission chains

The player should become more capable because of the choices they make, not simply because an XP bar became larger.

---

# Save System

The save system should preserve the player's state and important universe state.

```text
Player
├── Credits
├── Reputation
├── Current Ship
├── Ship Equipment
├── Cargo
├── Missions
└── Discoveries

Universe
├── Systems
├── Stations
├── Factions
├── Economy
├── Encounters
└── World Events

History
├── Completed Missions
├── Major Events
├── Faction Changes
└── Player Choices
```

Save data should remain independent from scene nodes wherever practical.

---

# Technical Direction

## Engine

**Godot 4.x**

## Language

**GDScript**

## Rendering

**3D**

The project should favour readable, stylised visuals over photorealism.

That keeps the art workload realistic while allowing strong silhouettes, lighting, effects and atmosphere.

---

# Architecture

The project separates **static data, runtime ship state, controllers, simulation and presentation**.

The central rule is:

> **The ship knows how to operate. The controller decides what it wants to do.**

~~~
Game
│
├── Universe
│   ├── Systems
│   ├── Factions
│   ├── Economy
│   ├── Missions
│   └── Encounters
│
├── Ships
│   ├── ShipData
│   ├── Ship
│   ├── Controllers
│   │   ├── Player
│   │   └── Enemy
│   ├── Weapons
│   └── Equipment
│
├── Simulation
│   ├── AI
│   ├── Economy
│   ├── Factions
│   ├── Missions
│   └── Encounters
│
├── Presentation
│   ├── Space
│   ├── Stations
│   ├── Planets
│   ├── Characters
│   └── UI
│
└── Save
~~~

The project should avoid a giant GameManager.gd that eventually knows about every system.

## Ship and Controller Separation

A ship is a reusable gameplay object.

~~~
Ship
├── ShipData
├── Runtime State
├── Flight Physics
├── Shields
├── Hull
├── Weapon System
├── Targeting
└── Equipment
~~~

Controllers provide intent to the ship.

~~~
PlayerShipController
	↓
Mouse / Keyboard Input
	↓
Flight Intent
	↓
Ship
~~~

~~~
EnemyShipController
	↓
AI Decisions
	↓
Flight Intent
	↓
Ship
~~~

The same ship implementation can therefore be controlled by the player, an enemy AI, an escort AI or another future controller without duplicating flight physics.

## Ship Loadouts and Weapon Mounts

Ship equipment is divided between **static capacity** and **runtime loadout**.

~~~
ShipData
├── weapon_slots
├── missile_slots
└── utility_slots
~~~

These values describe how many equipment slots the ship can support. They do not contain the weapons currently installed.

The runtime Ship owns the actual loadout:

~~~
Ship
├── ShipData
├── Runtime State
├── Weapon Loadout
│   ├── Weapon Slot 0
│   ├── Weapon Slot 1
│   └── ...
└── Equipment
~~~

A weapon is installed by taking a WeaponData definition, finding a compatible free slot, creating a runtime Weapon instance, attaching it to the ship's physical mount and assigning the owning Ship.

~~~
WeaponData
	↓
Equip
	↓
Available Weapon Slot
	↓
Weapon runtime instance
	↓
Physical Weapon Mount
	↓
Muzzle
	↓
Projectile
~~~

The physical ship scene contains named weapon mount points, for example:

~~~
Ship
└── WeaponMounts
	├── WeaponMount_0
	├── WeaponMount_1
	└── ...
~~~

`ShipData.weapon_slots` remains the gameplay capacity, while the scene's mount points determine where those weapons appear visually.

The same ShipData can therefore be reused by many different loadouts:

~~~
Starter Fighter
	↓
Player Ship
	└── Starter Laser

Starter Fighter
	↓
Enemy Ship
	└── Plasma Cannon
~~~

Weapon mass remains part of the runtime ship's total mass because WeaponData inherits from EquipmentData.

## Combat HUD

The prototype HUD reads directly from runtime ship and targeting state. It currently displays:

- Player speed and throttle.
- Player hull, shields and energy.
- Current target name and distance.
- Target hull and shields.
- Equipped weapon and firing readiness.
- The existing flight reticle and controls.

The HUD does not own targeting behaviour. Target selection and locking remain gameplay/controller responsibilities. The player can now acquire and cycle targets directly during the combat test.

## Target Locking

Target locking is now player-driven.

**T:** Lock the nearest valid ship. Press **T** again to cycle through nearby valid ships by distance.

The player controller decides when the input occurs, while TargetingSystem provides the valid target list, current target state and cycling logic. Destroyed or out-of-range ships are ignored.

~~~text
T
↓
TargetingSystem
↓
Valid ships within 1500 m
↓
Nearest target
↓
T again
↓
Next target
↓
Wrap around
~~~

The current target remains selected until the player cycles to another target or the target becomes invalid. The HUD reflects the active target lock immediately.

## Enemy AI State Machine

The first enemy combat AI uses a small state machine rather than embedding every behaviour directly into the flight controller.

~~~text
IDLE
  ↓ target found
PURSUIT
  ↓ within attack range
ATTACK
  ↓ shield damage / hull damage
EVADE
  ↓ timer expires
ATTACK
  ↓ critical hull
FLEE
  ↓ target lost
IDLE
~~~

### States

- **Idle:** No current target. The AI searches the shared ship group for a nearby valid target.
- **Pursuit:** Turns toward the target and closes the distance. Boost is used for long approaches.
- **Attack:** Maintains a preferred combat distance, uses lateral movement to orbit the target and requests weapon fire.
- **Evade:** Temporarily breaks from the attack pattern after taking damage, with low shields making the defensive response more deliberate.
- **Flee:** Attempts to escape when hull integrity becomes critical and remains in the escape state until the target is lost.

The state machine owns combat decisions. EnemyShipController only converts the resulting decision into the shared Ship flight-intent format.

The prototype enemy is equipped with the Starter Laser so these states can be exercised in a two-sided dogfight.

## Combat Prototype Test

The current prototype equips the player with two Starter Lasers at launch.

~~~
Left Mouse Button
	↓
Player fire intent
	↓
Equipped Weapon
	↓
Starter Laser Projectile
	↓
Projectile collision
~~~

The current test controls include:

- **Left Mouse Button:** Fire equipped weapon.
- **T:** Lock the nearest valid target or cycle to the next nearby target.
- The equipped weapons consume ship energy and observe their configured fire rate.
- Boost consumes ship energy continuously while active and stops when the tank is empty.
- Each equipped weapon spawns a projectile at its physical muzzle. Player-controlled fire converges from each muzzle toward the current screen-space cursor ray at target depth, so both guns align with the HUD crosshair; AI fire continues to use the weapon muzzle's forward direction.
- Projectile collision routes through the DamageSystem, which applies damage to the target ship's shields and hull.

The test equips the player with two Starter Lasers and the prototype enemy with one Starter Laser so the combat loop can be exercised from both sides. Both player weapons use the same weapon and projectile definition for now.

## Prototype Combat Reward

Destroying the prototype enemy with the player ship awards **100 credits**. The current prototype stores this as a temporary combat-test value in `main.gd` and displays the running total plus a short reward notification in the HUD.

This is intentionally not the final credits or progression system. Persistent credits, mission rewards, ship purchases and the wider economy belong to later milestones.

## Composition Over Ship Inheritance

Ships should not become a deep inheritance tree such as:

~~~
Ship
├── Fighter
│   └── PlayerFighter
├── EnemyFighter
├── Freighter
└── Gunship
~~~

Instead, ship identity comes from data and composition:

~~~
Ship
├── ShipData
├── Controller
├── Weapons
├── Shields
├── Equipment
└── Cargo
~~~

A player and an enemy can use the same ship definition while having different controllers.

# Proposed Project Structure

~~~
res://
├── assets/
│   ├── models/
│   ├── textures/
│   ├── materials/
│   ├── audio/
│   └── ui/
│
├── data/
│   ├── ships/
│   │   ├── ship_data.gd
│   │   └── *.tres
│   │
│   ├── weapons/
│   │   ├── weapon_data.gd
│   │   └── *.tres
│   │
│   ├── projectiles/
│   │   ├── projectile_data.gd
│   │   └── *.tres
│   │
│   ├── equipment/
│   ├── factions/
│   ├── missions/
│   ├── commodities/
│   ├── systems/
│   └── characters/
│
├── scenes/
│   ├── ships/
│   │   ├── ship.tscn
│   │   ├── player_ship.tscn
│   │   └── enemy_ship.tscn
│   │
│   ├── projectiles/
│   │   └── projectile.tscn
│   │
│   ├── weapons/
│   ├── player/
│   ├── space/
│   ├── stations/
│   ├── planets/
│   ├── characters/
│   ├── missions/
│   └── ui/
│
├── scripts/
│   ├── core/
│   ├── ships/
│   │   ├── ship.gd
│   │   ├── ship_controller.gd
│   │   ├── player_ship_controller.gd
│   │   └── enemy_ship_controller.gd
│   │
│   ├── combat/
│   │   ├── weapon.gd
│   │   ├── projectile.gd
│   │   ├── damage_system.gd
│   │   ├── shield_system.gd
│   │   └── targeting_system.gd
│   │
│   ├── missions/
│   ├── factions/
│   ├── economy/
│   ├── ai/
│   ├── world/
│   ├── boarding/
│   └── save/
│
└── shaders/
~~~

# Data-Driven Design

Static game content should use Godot **Resources**.

Runtime state should remain separate from the static definitions.

## ShipData

A ship resource describes the physical and gameplay design of a ship.

~~~
ShipData
├── Identity
│   ├── id
│   ├── display_name
│   └── description
│
├── Physical
│   ├── dimensions
│   └── hull_mass
│
├── Flight
│   ├── max_speed
│   ├── acceleration
│   ├── reverse_speed
│   ├── reverse_acceleration
│   ├── strafe_speed
│   ├── strafe_acceleration
│   ├── boost_speed
│   ├── boost_acceleration
│   ├── boost_energy_drain
│   ├── flight_assist_acceleration
│   ├── pitch_turn_rate
│   ├── yaw_turn_rate
│   ├── roll_turn_rate
│   └── turn acceleration
│
├── Combat
│   ├── hull_capacity
│   ├── shield_capacity
│   ├── energy_capacity
│   ├── shield_recharge_delay
│   ├── shield_recharge_rate
│   ├── energy_recharge_delay
│   └── energy_recharge_rate
│
├── Slots
│   ├── weapon_slots
│   ├── missile_slots
│   └── utility_slots
│
├── Cargo
│   └── cargo_capacity
│
└── Economy
	└── base_price
~~~

A ship resource contains **design inputs**, not derived flight results.

The runtime ship copies the direct flight values into runtime handling state. Mass and dimensions are not used to calculate turn rates or acceleration.

For the first implementation, dimensions and mass are deliberately approximate. We do not simulate the exact physical position of every component inside the hull.

## WeaponData

~~~
WeaponData
├── id
├── display_name
├── weapon_type
├── mass
├── damage
├── range
├── fire_rate
├── energy_cost
├── projectile_speed
└── projectile_data
~~~

Adding or removing installed equipment changes the ship's tracked equipment mass. It does not currently change flight handling. This leaves room to make mass matter later without coupling equipment to the control feel.

## EquipmentData

EquipmentData
├── id
├── display_name
└── mass_kg


Equipment is deliberately represented by a base resource so specialised equipment types, such as weapons, can inherit from it later.

## ProjectileData

~~~
ProjectileData
├── id
├── damage
├── speed
├── lifetime
├── radius
├── homing
├── turn_rate
└── visual_scene
~~~

The projectile definition is data. The runtime projectile handles movement, collision and applying the defined damage.

### Damage Delivery

Projectile hits are routed through a central DamageSystem rather than directly modifying ship state.

### Targeting

Each runtime Ship owns a TargetingSystem that stores and validates its current target.

~~~
Ship
└── TargetingSystem
	├── Current Target
	├── Target Validation
	├── Nearest Target Acquisition
	├── Target Distance
	└── Target Direction
~~~

The TargetingSystem is responsible for target state and safe target queries. It does not decide when the player locks, cycles or changes targets. Those higher-level behaviours belong to the later target-lock and AI systems.

Both player-facing systems and AI controllers can therefore use the same targeting API.


~~~
Projectile collision
	↓
DamageSystem
	↓
Target.receive_damage()
	↓
Current target hull
~~~

For the first combat prototype, incoming damage is absorbed by shields first. Any damage remaining after the shield capacity is depleted continues to the hull. Shield regeneration, directional shielding and shield-generator behaviour are deliberately deferred until they are needed.

The HullSystem now owns the basic hull damage calculation. The runtime Ship stores the current hull value and delegates overflow damage to HullSystem, keeping future armour, subsystem damage and destruction rules outside the projectile and damage dispatcher.

Shields now regenerate automatically after a configurable delay following combat damage. Energy regenerates after a shorter configurable delay following energy expenditure. Both delays and rates are defined by ShipData, while the runtime Ship owns the active timers and current resource values.

When hull reaches zero, DestructionSystem transitions the runtime Ship into a destroyed state. The wreck remains in the scene, flight and weapon control stop, its collision is disabled and a `destroyed` signal is emitted for later systems such as rewards, salvage, boarding or visual effects.


## Runtime State

Static data should not contain changing gameplay state.

~~~
ShipData
	↓
Static definition

Ship
	↓
Current hull
Current shields
Current energy
Current velocity
Current throttle
Current equipment
Current cargo
~~~

This lets one ShipData resource be reused by many ships while every ship maintains its own runtime state.

# Architecture Rules

- Keep gameplay data separate from presentation.
- Use Resources for static definitions.
- Keep runtime state separate from static data.
- Separate controllers from reusable gameplay objects.
- Prefer composition over giant inheritance trees.
- Ship flight physics should not depend on whether the controller is human or AI.
- Keep flight handling based on direct gameplay-tuned values.
- Keep ship dimensions and mass available for systems that actually need them, without using them to determine basic handling.
- Equipment should contribute to runtime ship mass where appropriate.
- Keep ships modular.
- Keep weapons and projectiles data-driven.
- Use signals for loosely coupled events.
- Avoid unnecessary global state.
- Keep systems small enough to test.
- Prefer deterministic simulation where practical.
- Do not build a system until the gameplay needs it.
- Simulation depth should serve gameplay rather than become the project.

---

# Prototype Philosophy

The biggest trap is:

> **"We need a galaxy before we can make the game."**

We do not.

The first prototype should contain only the pieces required to prove the core loop:

~~~
One small space environment
		↓
Reusable Ship
		↓
ShipData
		↓
Player Controller
		↓
Enemy Controller
		↓
Weapon
		↓
Projectile
		↓
Damage
		↓
Dogfight
~~~

The first combat prototype should use:

- One player ship
- One enemy ship
- One ship definition
- One weapon definition
- One projectile definition
- Basic targeting
- Basic AI
- Shields
- Hull
- Destruction

If the resulting dogfight is not fun, adding forty star systems only gives us forty places where the game is not fun.

---

# Development Roadmap

## Milestone 0 - Project Foundation

**Status: RESET / NEW DIRECTION**

- [x] Establish 3D project structure
- [x] Establish core autoloads
- [x] Establish save/load architecture
- [x] Establish data-resource conventions
- [x] Establish main game scene
- [x] Remove old civilization prototype assumptions

---

## Milestone 1 - First Flight

**Status: FOUNDATION COMPLETE**

The reusable ship, controller and flight model foundation is in place.

---

## Milestone 2 - Combat

**Goal: Build the reusable combat foundation, then make one dogfight fun.**

### Ship Foundation

- [x] ShipData Resource
- [x] Ship runtime scene
- [x] Ship runtime state
- [x] ShipController base
- [x] PlayerShipController
- [x] EnemyShipController
- [x] Ship spawning
- [x] Direct gameplay-tuned flight physics
- [x] Equipment tracking remains separate from flight handling

### Combat Foundation

- [x] WeaponData Resource
- [x] Weapon runtime
- [x] ProjectileData Resource
- [x] Projectile runtime
- [x] Damage system
- [x] Shields
- [x] Hull
- [x] Destruction
- [x] Targeting system
- [x] Combat HUD
- [x] Shield and energy regeneration

### Dogfight

- [x] Enemy AI
- [x] Target locking
- [x] Basic weapon
- [x] Projectile firing
- [x] Player damage
- [x] Enemy damage
- [x] Enemy destruction
- [x] Basic reward

**Definition of done:** The player and an enemy use the same reusable ship system with different controllers, can target each other, fight, take damage and be destroyed.

---


## Milestone 3 - Combat HUD and Targeting Feedback

**Goal: Make the dogfight readable at a glance and give the player clear visual feedback about targets, incoming fire and where to aim.**

The combat HUD should communicate spatial information in 2D while remaining driven by the existing 3D gameplay state.

### Target Feedback

- [x] Target lock bracket that follows the current target on screen
- [x] Off-screen target direction arrow
- [x] Target bracket / off-screen indicator transition and screen-edge clamping

### Incoming Damage Feedback

- [x] Directional damage indicator around the player HUD
- [x] Convert the world-space damage source into a temporary 2D red arc
- [x] Support damage coming from any direction around the player

### Aiming Feedback

- [x] Graphical player crosshair
- [x] Projectile lead / aim indicator circle
- [x] Lead calculation based on target movement, relative motion and actual projectile speed
- [x] Lead indicator updates when the target or equipped weapon changes

### HUD Architecture

- [x] Keep target bracket, direction arrow, damage indicator and lead indicator as separate HUD components
- [x] Keep targeting decisions in TargetingSystem / controllers rather than the HUD
- [x] Reuse runtime Ship and Weapon/Projectile data as the source of truth

**Definition of done:** During a dogfight, the player can immediately see which ship is locked, where that ship is when off-screen, which direction incoming damage came from and where to aim for a likely projectile interception.

---

## Milestone 4 - First Station

**Goal: Give the player somewhere to go.**

- [ ] Space station
- [ ] Docking detection
- [ ] Docking sequence
- [ ] Station scene
- [ ] Repair
- [ ] Equipment shop
- [ ] Basic station UI
- [ ] Save at station

---

## Milestone 5 - Missions

**Goal: Give the player a reason to fly.**

- [ ] Mission Resources
- [ ] Mission manager
- [ ] Mission board
- [ ] Delivery mission
- [ ] Combat mission
- [ ] Objectives
- [ ] Rewards
- [ ] Completion
- [ ] Failure
- [ ] Persistence

---

## Milestone 6 - Economy

- [ ] Commodities
- [ ] Cargo hold
- [ ] Buy cargo
- [ ] Sell cargo
- [ ] Station inventories
- [ ] Basic price differences
- [ ] Trading mission
- [ ] Cargo UI
- [ ] Cargo upgrades

---

## Milestone 7 - Player Progression

- [ ] Credits
- [ ] Ship upgrades
- [ ] Equipment slots
- [ ] Multiple weapons
- [ ] Multiple ships
- [ ] Ship purchasing
- [ ] Ship switching

---

## Milestone 8 - Factions and Reputation

- [ ] Faction data
- [ ] Reputation
- [ ] Friendly / neutral / hostile states
- [ ] Faction mission pools
- [ ] Reputation rewards
- [ ] Reputation penalties
- [ ] Restricted stations
- [ ] Faction equipment

---

## Milestone 9 - Living Space

- [ ] Third-person character controller
- [ ] Station interior
- [ ] NPC interaction
- [ ] Dialogue
- [ ] Mission contacts
- [ ] Shops
- [ ] Terminals
- [ ] First planetary location

This remains focused. We are building playable locations, not an entire open-world planet.

---

## Milestone 10 - Boarding

- [ ] Disable enemy ship
- [ ] Boarding trigger
- [ ] Boarding transition
- [ ] Ship interior
- [ ] Enemy crew
- [ ] Boarding objectives
- [ ] Cargo theft
- [ ] Sabotage
- [ ] Ship capture
- [ ] Boarding rewards
- [ ] Boarding failure

---

## Milestone 11 - Dynamic Universe

- [ ] NPC traffic
- [ ] Traders
- [ ] Police
- [ ] Pirates
- [ ] Mining ships
- [ ] Convoys
- [ ] Distress calls
- [ ] Dynamic encounters
- [ ] Local faction activity
- [ ] World events

---

## Milestone 12 - Exploration

- [ ] Scanner
- [ ] Unknown contacts
- [ ] Derelicts
- [ ] Hidden locations
- [ ] Resource fields
- [ ] Anomalies
- [ ] Secret stations
- [ ] Discovery rewards

---

## Milestone 13 - Larger Universe

Only after the core game works:

- [ ] Multiple systems
- [ ] Jump gates
- [ ] Fast travel
- [ ] System maps
- [ ] Inter-system economy
- [ ] More factions
- [ ] More stations
- [ ] More ships
- [ ] More mission types

---

# Long-Term Ideas

These are deliberately **not** early-development requirements.

Potential future systems:

- Ship capture
- Persistent ship interiors
- Crew with skills and personalities
- Faction wars
- Dynamic economy
- Procedural contracts
- Persistent important NPCs
- Smuggling
- Salvage fields
- Detailed subsystem damage
- Destructible cargo
- Player-owned stations
- Larger faction territories
- More sophisticated AI

---

# What Makes This Different

The classic foundation remains:

- Open space travel
- Space combat
- Trading
- Missions
- Factions
- Reputation
- Ship upgrades
- Story progression

The newer direction adds:

- **Hybrid world structure**
- **Playable station and planetary interiors**
- **Varied boarding**
- **Dynamic mission generation**
- **Reactive factions**
- **Living local economies**
- **NPCs with actual purposes**
- **Player actions that can alter local situations**
- **Modular ships and equipment**
- **Scanner-driven exploration**

The goal is not to make a larger Freelancer.

The game's overall presentation is **Freelancer-inspired space gameplay combined with a more third-person, GTA 3-style character experience when the player leaves the ship**.

The goal is to make a **modern space RPG that connects space combat, atmospheric combat and focused planetary exploration into one continuous experience**.

---

# Current Design Target

The first complete gameplay session should feel like this:

```text
Start with a cheap ship
		↓
Leave frontier station
		↓
Accept delivery contract
		↓
Fly through open space
		↓
Detect distress signal
		↓
Investigate
		↓
Fight pirates
		↓
Rescue merchant
		↓
Gain reputation
		↓
Complete delivery
		↓
Return to station
		↓
Sell cargo
		↓
Repair ship
		↓
Buy better weapon
		↓
Accept bounty
		↓
Launch again
```

That loop is the heart of the project.

---

# Development Rules

## Build vertically before horizontally

One complete playable loop is more valuable than ten unfinished systems.

## Prototype with ugly assets

Primitive meshes are fine.

A grey spaceship that is fun to fly is more useful than a beautiful spaceship that cannot fly.

## Avoid premature complexity

Start with the simplest implementation that proves the gameplay.

Complexity should be earned.

## Every major system needs a reason

Every feature should answer:

> **What does this allow the player to do?**

If the only answer is "make the simulation more realistic", it probably does not belong in the early game.

---

# Current Status

**Early prototype / major redesign.**

The repository previously contained an experimental civilization simulation.

The project is now being redirected toward a **3D Freelancer-inspired space RPG built in Godot and GDScript**.

The initial flight prototype is complete, but its architecture is now being refactored before combat.

The immediate objective is:

> **Build one excellent dogfight before building the rest of the universe.**

The longer-term technical prototype will then prove the seamless planetary loop: **space flight → atmosphere → planetary dogfight → landing → third-person surface interaction → takeoff**.

The reusable ship, combat, targeting and enemy AI foundations are now in place. The current focus is combat HUD feedback: making targeting, incoming fire and aiming information immediately readable without adding unnecessary simulation complexity.

---

# Ultimate Vision

The long-term game should let the player:

- Fly through a connected universe.
- Make money through different careers.
- Upgrade and customise ships.
- Build relationships with factions.
- Leave the cockpit.
- Explore stations and planetary locations.
- Board enemy vessels.
- Discover hidden locations.
- Follow the main story or ignore it.
- Encounter situations that emerge from the world.
- Become a trader, mercenary, explorer, pirate, smuggler or something in between.

The universe should not ask:

> **"What mission are you supposed to do?"**

It should ask:

> **"What are you going to do?"**
