# Unnamed Space Game

A **3D single-player space RPG inspired by Freelancer**, built in **Godot 4.x with GDScript**.

The goal is to take the accessible space-flight, trading, combat and mission structure of classic space RPGs and combine it with newer ideas: **hybrid world structure, explorable station interiors, varied boarding, dynamic missions, reactive factions and a living local economy**.

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
5. **The player can leave the cockpit.** Stations and selected planetary locations are playable spaces.
6. **Boarding matters.** Disabled ships can become opportunities rather than automatic explosions.
7. **Build vertically first.** One excellent playable system is more valuable than twenty unfinished systems.
8. **Keep it finishable.** Simulation depth should serve gameplay, not become the project.

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

# Space Flight

Space flight is the foundation of the game.

The player controls a 3D spacecraft using an accessible **twin-stick-inspired control scheme** rather than a full flight simulator.

## Controls

- Pitch
- Yaw
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

The ship should have acceleration and momentum while remaining responsive enough for close combat.

## Flight Model

Flight characteristics are **derived from the physical properties of the ship and its propulsion**, rather than being manually assigned values for every ship.

The model is intentionally **physical-feeling**, not a full spacecraft simulator.

Each ship defines a small set of approximate design specifications:

text
Hull dimensions
Hull mass
Main engine thrust
Reverse thrust
Maneuvering / RCS thrust
Boost thrust
Equipment
Cargo
text

From these values the runtime ship derives:

text
Total mass
Acceleration
Reverse acceleration
Brake acceleration
Strafe acceleration
Boost acceleration
Pitch behaviour
Yaw behaviour
Roll behaviour
Stopping time
Stopping distance
text

The basic relationships are:

text
Linear acceleration = thrust / mass

Braking acceleration = reverse thrust / mass

Stopping time = current speed / braking acceleration

Stopping distance = current speed² / (2 × braking acceleration)

Angular acceleration = torque / moment of inertia
text

For rotational behaviour, ship dimensions and total mass are used to **approximate the ship's moment of inertia**. The game does not simulate the physical position of individual components such as reactors, cargo or weapons.

This gives larger and heavier ships naturally different handling from small, agile ships without requiring individually hand-tuned flight statistics.

### Throttle and Momentum

Throttle and velocity are separate concepts.

text
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
text

The brake therefore **kills momentum rather than simply setting throttle to zero**.

Turning and rolling do not automatically redirect existing velocity. A ship can rotate while continuing along its current trajectory.

### Boost

Boost increases available propulsion rather than directly setting the ship to an arbitrary speed.

text
Normal engine thrust
        ↓
Normal acceleration

Boost engine thrust
        ↓
Higher acceleration
        ↓
Higher practical speed
text

The exact top speed remains a gameplay constraint because a ship in empty space would otherwise continue accelerating for as long as thrust is applied.

## Ship States

text
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
text

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

One of the major additions beyond classic Freelancer-style gameplay is the ability to **leave the cockpit**.

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

Planetary locations follow the same principle.

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

text
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
text

The project should avoid a giant GameManager.gd that eventually knows about every system.

## Ship and Controller Separation

A ship is a reusable gameplay object.

text
Ship
├── ShipData
├── Runtime State
├── Flight Physics
├── Shields
├── Hull
├── Weapon System
├── Targeting
└── Equipment
text

Controllers provide intent to the ship.

text
PlayerShipController
    ↓
Mouse / Keyboard Input
    ↓
Flight Intent
    ↓
Ship
text

text
EnemyShipController
    ↓
AI Decisions
    ↓
Flight Intent
    ↓
Ship
text

The same ship implementation can therefore be controlled by the player, an enemy AI, an escort AI or another future controller without duplicating flight physics.

## Composition Over Ship Inheritance

Ships should not become a deep inheritance tree such as:

text
Ship
├── Fighter
│   └── PlayerFighter
├── EnemyFighter
├── Freighter
└── Gunship
text

Instead, ship identity comes from data and composition:

text
Ship
├── ShipData
├── Controller
├── Weapons
├── Shields
├── Equipment
└── Cargo
text

A player and an enemy can use the same ship definition while having different controllers.

# Proposed Project Structure

text
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
text

# Data-Driven Design

Static game content should use Godot **Resources**.

Runtime state should remain separate from the static definitions.

## ShipData

A ship resource describes the physical and gameplay design of a ship.

text
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
├── Propulsion
│   ├── main_engine_thrust
│   ├── reverse_engine_thrust
│   ├── maneuvering_thrust
│   └── boost_thrust
│
├── Combat
│   ├── hull_capacity
│   ├── shield_capacity
│   └── energy_capacity
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
text

A ship resource contains **design inputs**, not derived flight results.

The runtime ship calculates its actual handling from those inputs.

For the first implementation, dimensions and mass are deliberately approximate. We do not simulate the exact physical position of every component inside the hull.

## WeaponData

text
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
text

Adding or removing a weapon changes the ship's total mass.

## ProjectileData

text
ProjectileData
├── id
├── damage
├── speed
├── lifetime
├── radius
├── homing
├── turn_rate
└── visual_scene
text

The projectile definition is data. The runtime projectile handles movement, collision and applying the defined damage.

## Runtime State

Static data should not contain changing gameplay state.

text
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
text

This lets one ShipData resource be reused by many ships while every ship maintains its own runtime state.

# Architecture Rules

- Keep gameplay data separate from presentation.
- Use Resources for static definitions.
- Keep runtime state separate from static data.
- Separate controllers from reusable gameplay objects.
- Prefer composition over giant inheritance trees.
- Ship flight physics should not depend on whether the controller is human or AI.
- Calculate derived flight characteristics from physical inputs.
- Approximate ship dimensions and mass rather than simulating exact component positions.
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

text
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
text

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

**Status: FOUNDATION COMPLETE / ARCHITECTURE REWORK IN PROGRESS**

**Goal: Make flying a spaceship fun, then move the flight model into reusable ship architecture.**

Flight prototype completed:

- [x] Player ship scene
- [x] Third-person space camera
- [x] Pitch
- [x] Yaw
- [x] Roll
- [x] Throttle
- [x] Boost
- [x] Brake
- [x] Strafe
- [x] Acceleration
- [x] Flight HUD
- [x] Center flight reticle
- [x] Flight test markers
- [x] Camera smoothing
- [x] Boost camera FOV
- [x] Rotation basis stabilization
- [x] Pilot-relative yaw controls

Before combat, the prototype flight code will be refactored into the reusable ship architecture.

The final Milestone 1 flight model should use:

- [ ] ShipData Resource
- [ ] Reusable Ship
- [ ] ShipController base
- [ ] PlayerShipController
- [ ] Formula-derived flight characteristics
- [ ] Physical-feeling throttle and momentum
- [ ] Mass affected by installed equipment

**Definition of done:** A reusable ship can be controlled independently of the controller, and its flight characteristics are calculated from its dimensions, mass and propulsion specifications.

---

## Milestone 2 - Combat

**Goal: Build the reusable combat foundation, then make one dogfight fun.**

### Ship Foundation

- [ ] ShipData Resource
- [ ] Ship runtime scene
- [ ] Ship runtime state
- [ ] ShipController base
- [ ] PlayerShipController
- [ ] EnemyShipController
- [ ] Ship spawning
- [ ] Formula-derived flight physics
- [ ] Equipment contributes to ship mass

### Combat Foundation

- [ ] WeaponData Resource
- [ ] Weapon runtime
- [ ] ProjectileData Resource
- [ ] Projectile runtime
- [ ] Damage system
- [ ] Shields
- [ ] Hull
- [ ] Destruction
- [ ] Targeting system
- [ ] Combat HUD

### Dogfight

- [ ] Enemy AI
- [ ] Target locking
- [ ] Basic weapon
- [ ] Projectile firing
- [ ] Player damage
- [ ] Enemy damage
- [ ] Enemy destruction
- [ ] Basic reward

**Definition of done:** The player and an enemy use the same reusable ship system with different controllers, can target each other, fight, take damage and be destroyed.

---

## Milestone 3 - First Station

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

## Milestone 4 - Missions

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

## Milestone 5 - Economy

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

## Milestone 6 - Player Progression

- [ ] Credits
- [ ] Ship upgrades
- [ ] Equipment slots
- [ ] Multiple weapons
- [ ] Multiple ships
- [ ] Ship purchasing
- [ ] Ship switching

---

## Milestone 7 - Factions and Reputation

- [ ] Faction data
- [ ] Reputation
- [ ] Friendly / neutral / hostile states
- [ ] Faction mission pools
- [ ] Reputation rewards
- [ ] Reputation penalties
- [ ] Restricted stations
- [ ] Faction equipment

---

## Milestone 8 - Living Space

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

## Milestone 9 - Boarding

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

## Milestone 10 - Dynamic Universe

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

## Milestone 11 - Exploration

- [ ] Scanner
- [ ] Unknown contacts
- [ ] Derelicts
- [ ] Hidden locations
- [ ] Resource fields
- [ ] Anomalies
- [ ] Secret stations
- [ ] Discovery rewards

---

## Milestone 12 - Larger Universe

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

The goal is to make a **modern space RPG that starts from the same appealing foundation**.

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

Milestone 1 is now complete. The immediate objective is:

> **Build one excellent dogfight before building a universe.**

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
