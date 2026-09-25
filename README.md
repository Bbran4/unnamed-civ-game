# Unnamed Space Game

A **3D single-player space RPG inspired by Freelancer**, built in **Godot 4.x with GDScript**.

The goal is to take the accessible space-flight, trading, combat and mission structure of classic space RPGs and combine it with newer ideas: **third-person planetary gameplay, seamless space-to-atmosphere flight, continuous procedural planetary wilderness, explorable station and planetary locations, varied boarding, dynamic missions, reactive factions and a living local economy**.

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
5. **The player can leave the cockpit.** Stations and planetary locations are playable third-person spaces.
6. **Planets are continuous gameplay spaces.** The player can fly into atmospheres, fight in the air, travel across endless procedural wilderness, land, and explore focused surface locations.
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

It is not intended to be one completely seamless galaxy. Instead, the universe combines large navigable space regions with detailed stations, continuous planetary surfaces and interior spaces.

```text
Galaxy
 ├── Sector
 │    ├── Star System
 │    │    ├── Planet (continuous procedural surface)
 │    │    ├── Orbital Station
 │    │    ├── Asteroid Field
 │    │    ├── Trade Route
 │    │    └── Hidden Location
 │    └── ...
 └── ...
```

This lets the project create detailed locations and continuous planetary wilderness without requiring an enormous seamless galaxy simulation.

---

# Planetary Gameplay

Planets are not separate walking-only levels. They are **continuous gameplay spaces connected to space flight**.

The player should be able to fly toward a planet, enter its atmosphere, fight enemy fighters and other aerial threats, travel across the surface, land, leave the ship and interact with people or objects without a traditional loading-screen transition.

## Design Intent

The game is **not** intended to reproduce every planetary activity found in No Man's Sky. Ground gameplay remains focused and mission-driven. The player mainly visits specific areas to find someone, investigate a location, recover an object, meet an NPC or pursue a mission objective.

At the same time, the planetary wilderness itself should be effectively **endless**. The player should be able to keep flying across a planet and encounter continuous procedural terrain rather than reaching an artificial world boundary. Detailed settlements and mission locations sit on top of this procedural wilderness rather than replacing it.

Mining is primarily a **space activity involving asteroid fields**, rather than underground planetary mining.

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
Descend / travel across wilderness
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

Ground environments combine two layers:

1. **Endless procedural wilderness** — continuous terrain the player can fly over and land on anywhere.
2. **Focused third-person locations** — denser, authored or carefully placed areas where most mission and social gameplay happens.

Possible focused locations include:
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
- Explore the surrounding wilderness.
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

The goal is **seamless presentation with effectively endless planetary wilderness**, not an unnecessarily huge simulation. Planetary detail should increase as the player approaches the surface, while distant planetary visuals remain inexpensive. Terrain is generated and streamed around the player so there is no designed "edge of the map".

### Endless Planetary Wilderness

Planets should not be small handcrafted maps surrounded by invisible boundaries. Their wilderness is intended to continue procedurally across the planet.

The technical target is:

```text
Planet
	↓
Planetary coordinates
	↓
Deterministic terrain generation
	↓
Streaming terrain tiles
	↓
Nearby high-detail terrain
	↓
Distant low-detail terrain
```

Only terrain near the player needs to exist at full resolution. As the player travels, tiles behind them can be unloaded and new tiles generated ahead of them from the same planetary coordinates and seed.

This allows a planet to feel effectively endless while keeping memory and rendering costs bounded.

Important constraints:
- No finite terrain map.
- No visible terrain loading during normal travel.
- Deterministic terrain so revisiting an area produces the same world.
- Terrain must support atmospheric flight, landing and third-person surface gameplay.
- Detailed settlements and mission locations are placed on top of the procedural wilderness rather than replacing it.
- Underground voxel mining and fully simulated planetary interiors are not required.

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

```text
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
```

This keeps flight tuning simple. A ship resource directly answers questions such as:

> How fast is this ship?
> How quickly does it accelerate?
> How quickly can it turn?
> How responsive should it feel?

Turn rates are stored in degrees per second, while turn acceleration controls how quickly the ship reaches its requested rate. The mouse cursor maps to a requested turn rate, so moving the cursor farther from the screen centre asks for a stronger turn rather than directly rotating the ship.

Mass and dimensions can still matter to cargo, equipment, collision, visuals and other future systems. They are deliberately **not** part of the current flight equation.

### Throttle and Momentum

Throttle and velocity are separate concepts.

```text
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
```

The brake therefore **kills momentum rather than simply setting throttle to zero**.

Turning and rolling do not automatically redirect existing velocity. A ship can rotate while continuing along its current trajectory.

### Boost

Boost uses its own direct gameplay values.

```text
Boost active
		↓
Higher acceleration
		↓
Higher speed limit
```

Each ship can therefore be tuned independently for normal speed, boost speed and how quickly it reaches those speeds.

## Ship States

```text
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
```

Other states can include:

- Disabled
- Boarding
- Jumping
- Salvaging
- Destroyed

---

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

On stations and at focused planetary locations the player can exit the ship and move on foot.

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
- Explore the immediate wilderness around a landed ship.

Planetary locations sit on top of the continuous procedural surface. The player can land almost anywhere, but denser gameplay (NPCs, shops, mission objectives) is concentrated in focused locations.

A planet may contain detailed:

- Spaceports
- Mining towns
- Research facilities
- Military bases
- Industrial colonies
- Frontier settlements

These exist within the larger continuous wilderness rather than being the only places the player can land.

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

```text
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
```

The project should avoid a giant GameManager.gd that eventually knows about every system.

## Ship and Controller Separation

A ship is a reusable gameplay object.

```text
Ship
├── ShipData
├── Runtime State
├── Flight Physics
├── Shields
├── Hull
├── Weapon System
├── Targeting
└── Equipment
```

Controllers provide intent to the ship.

```text
PlayerShipController
	↓
Mouse / Keyboard Input
	↓
Flight Intent
	↓
Ship
```

```text
EnemyShipController
	↓
AI Decisions
	↓
Flight Intent
	↓
Ship
```

The same ship implementation can therefore be controlled by the player, an enemy AI, an escort AI or another future controller without duplicating flight physics.

## Composition Over Ship Inheritance

Ships should not become a deep inheritance tree. Instead, ship identity comes from data and composition:

```text
Ship
├── ShipData
├── Controller
├── Weapons
├── Shields
├── Equipment
└── Cargo
```

A player and an enemy can use the same ship definition while having different controllers.

---

# Prototype Philosophy

The biggest trap is:

> **"We need a galaxy before we can make the game."**

We do not.

The first prototype should contain only the pieces required to prove the core loop. If the resulting dogfight is not fun, adding forty star systems only gives us forty places where the game is not fun.

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

**Status: largely complete.**

---

## Milestone 3 - Combat HUD and Targeting Feedback
**Goal: Make the dogfight readable at a glance.**

**Status: largely complete.**

---

## Milestone 4 - Seamless Planetary Flight
**Goal: Prove continuous space → atmosphere → surface flight, including endless procedural wilderness.**

- [x] Planetary altitude calculation
- [x] Space / atmosphere / surface flight environment state
- [x] Planet-aware atmospheric flight tracking
- [x] Atmospheric drag foundation
- [ ] Smooth atmospheric visual transition
- [ ] Atmospheric flight tuning
- [ ] Planetary gravity
- [ ] Surface approach
- [ ] Procedural terrain prototype
- [ ] Streamed terrain tiles
- [ ] Terrain collision
- [ ] Landing detection
- [ ] Takeoff back into atmosphere
- [ ] Seamless return to space
- [ ] Deterministic planetary coordinates
- [ ] Tile streaming with load/unload around the player

**Definition of done:** The player can fly from open space into a planet's atmosphere, continue flying over continuous procedural terrain with no world edge, land, take off and return to space without a scene-loading transition.

---

## Milestone 5 - First Station
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

## Milestone 6 - Missions
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

## Milestone 7 - Economy

- [ ] Commodities
- [ ] Cargo hold
- [ ] Buy / sell cargo
- [ ] Station inventories
- [ ] Basic price differences
- [ ] Trading mission
- [ ] Cargo UI

---

## Milestone 8 - Player Progression

- [ ] Credits
- [ ] Ship upgrades
- [ ] Equipment slots
- [ ] Multiple weapons / ships
- [ ] Ship purchasing and switching

---

## Milestone 9 - Factions and Reputation

- [ ] Faction data
- [ ] Reputation
- [ ] Friendly / neutral / hostile states
- [ ] Faction mission pools
- [ ] Reputation rewards / penalties
- [ ] Restricted stations

---

## Milestone 10 - Living Space

- [ ] Third-person character controller
- [ ] Station interior
- [ ] NPC interaction
- [ ] Dialogue
- [ ] Mission contacts
- [ ] Shops
- [ ] Terminals
- [ ] First focused planetary location on top of procedural wilderness

Focused locations provide dense gameplay. The surrounding wilderness remains continuous and landable.

---

## Milestone 11 - Boarding

- [ ] Disable enemy ship
- [ ] Boarding trigger and transition
- [ ] Ship interior
- [ ] Enemy crew
- [ ] Boarding objectives, theft, sabotage, capture
- [ ] Rewards and failure states

---

## Milestone 12 - Dynamic Universe

- [ ] NPC traffic (traders, police, pirates, mining ships, convoys)
- [ ] Distress calls and dynamic encounters
- [ ] Local faction activity and world events

---

## Milestone 13 - Exploration

- [ ] Scanner
- [ ] Unknown contacts, derelicts, hidden locations
- [ ] Resource fields, anomalies, secret stations
- [ ] Discovery rewards

---

## Milestone 14 - Larger Universe

Only after the core game works:

- [ ] Multiple systems
- [ ] Jump gates
- [ ] Fast travel
- [ ] System maps
- [ ] Inter-system economy
- [ ] More factions, stations, ships and mission types

---

# Long-Term Ideas

These are deliberately **not** early-development requirements.

- Ship capture and persistent ship interiors
- Crew with skills and personalities
- Faction wars and dynamic economy
- Procedural contracts and persistent important NPCs
- Smuggling, salvage fields, detailed subsystem damage
- Player-owned stations and larger faction territories

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
- **Seamless space-to-atmosphere-to-surface flight**
- **Continuous procedural planetary wilderness**
- **Focused mission locations on top of that wilderness**
- **Playable station and planetary interiors**
- **Varied boarding**
- **Dynamic mission generation**
- **Reactive factions**
- **Living local economies**
- **NPCs with actual purposes**
- **Modular ships and equipment**
- **Scanner-driven exploration**

The goal is not to make a larger Freelancer.

The game's overall presentation is **Freelancer-inspired space gameplay combined with continuous planetary flight and a more third-person character experience when the player leaves the ship**.

The goal is to make a **modern space RPG that connects space combat, atmospheric combat and continuous planetary exploration into one continuous experience**.

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
Primitive meshes are fine. A grey spaceship that is fun to fly is more useful than a beautiful spaceship that cannot fly.

## Avoid premature complexity
Start with the simplest implementation that proves the gameplay. Complexity should be earned.

## Every major system needs a reason
Every feature should answer:

> **What does this allow the player to do?**

If the only answer is "make the simulation more realistic", it probably does not belong in the early game.

---

# Current Status

**Early prototype / major redesign.**

The reusable ship, combat, targeting and enemy AI foundations are now in place.

The longer-term technical prototype will prove the seamless planetary loop:

**space flight → atmosphere → planetary dogfight → continuous procedural wilderness → landing → third-person surface interaction → takeoff**.

---

# Ultimate Vision

The long-term game should let the player:

- Fly through a connected universe.
- Make money through different careers.
- Upgrade and customise ships.
- Build relationships with factions.
- Leave the cockpit.
- Explore stations and continuous planetary surfaces.
- Board enemy vessels.
- Discover hidden locations.
- Follow the main story or ignore it.
- Encounter situations that emerge from the world.
- Become a trader, mercenary, explorer, pirate, smuggler or something in between.

The universe should not ask:

> **"What mission are you supposed to do?"**

It should ask:

> **"What are you going to do?"**
