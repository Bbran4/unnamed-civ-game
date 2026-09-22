# Unnamed Space Game

A top-down 2D space RPG inspired by **Freelancer, GTA 2 and Star Valor**.

The player flies a ship through a living space economy, docks at stations, walks around on foot, trades goods, fights, salvages wrecks, boards ships and eventually takes on missions that react to the world around them.

The game is deliberately built as a **hybrid world**. Space, stations, planetary locations and ship interiors are separate Godot scenes connected through transitions. This keeps the project achievable while still letting the player move between different layers of the world.

## Core Identity

**Freelancer-style space RPG + Star Valor-style ship combat + GTA 2-style top-down exploration and interaction.**

### Gameplay Modes

- **Space Mode:** Fly, fight, travel, dock, trade and salvage.
- **Station Mode:** Leave the ship, walk around stations, visit services and interact with NPCs.
- **Boarding Mode:** Enter ship interiors and complete contained objectives.
- **World Simulation:** Planets, stations, factions, resources, production and prices create the underlying world.

The player should feel like they are moving through a place that exists independently of whatever mission they currently have. Space itself should feel physical: stars have mass, planets follow stable orbits, moons and stations orbit planets, and ships inherit the motion of the bodies they are near.

---

# Design Pillars

1. **The world comes first.** Planets, stations, factions and markets should make sense before missions are layered on top.
2. **Space and ground are both playable.** The ship is not just a menu with wings.
3. **The economy should create opportunities.** Shortages, production and demand should naturally create reasons to travel.
4. **Systems should interact.** A shortage of one resource should be capable of affecting several goods and stations.
5. **Keep the scope finishable.** Build one convincing system before attempting a giant galaxy.
6. **Every milestone should leave the game playable.**
7. **Data describes the universe. Generators create it. Managers simulate it. Scenes display it.**

---

# Core Gameplay Loop

The long-term loop is intended to emerge from the world rather than being completely scripted:

**Explore → Discover Opportunity → Travel → Trade / Fight / Salvage / Board → Earn Credits → Upgrade → Reach New Opportunities**

Examples:

**Cheap Fuel → Buy Cargo → Travel to Shortage → Sell for Profit → Upgrade Ship**

**Mining Shortage → Industrial Production Falls → Manufactured Goods Become Scarce → Prices Rise → Trade Opportunity Appears**

**Hostile Ship → Fight → Disable → Board → Recover Cargo → Sell Cargo**

Missions will eventually sit on top of these systems instead of being the only reason the player does anything.

---

# Space Combat

The primary ship control style is inspired by **Star Valor**.

### Default Controls

| Input | Action |
|---|---|
| W | Accelerate forward |
| S | Reverse / brake |
| A / D | Rotate |
| Shift | Boost |
| Left Mouse Button | Fire primary weapon |
| Right Mouse Button | Secondary weapon |
| E | Dock / interact |
| M | Open star map |
| Tab | Target |
| Esc | Pause / menu |

An alternate mouse-aim control style exists for testing.

### Initial Ship Systems

- [x] Hull
- [x] Modular shields
- [x] Shield regeneration when a shield module is installed
- [x] Shield HUD hidden when no shield module is installed
- [x] Acceleration
- [x] Maximum speed
- [x] Reverse movement
- [x] Boost
- [x] Primary weapon
- [x] Projectiles
- [x] Damage and destruction
- [x] Salvage
- [x] Credits
- [x] Enemy combat
- [x] Warp danger detection
- [x] Hyperdrive travel within a system
- [x] Warp travel between systems

The combat model should remain arcade-like and responsive. More detailed ship systems can be added only when they improve the game.

---

# Stations and On-Foot Exploration

Stations are physical locations rather than menus.

The player can:

- [x] Dock with a station
- [x] Leave the ship
- [x] Walk around
- [x] Talk to NPCs
- [x] Use terminals
- [x] Visit markets
- [x] Return to the ship
- [x] Launch back into space

Station interiors are separate scenes.

The current prototype contains:

- Docking bay
- Top-down player movement
- Docked ship
- Dockmaster NPC
- Station market terminal
- Station-to-space return

---

# The World

The world is built around a simple hierarchy:

```text
Galaxy
└── Star System
	├── Planets
	│   ├── Type
	│   ├── Size
	│   ├── Gravity
	│   ├── Temperature
	│   ├── Population
	│   └── Resources
	│
	└── Stations
		├── Type
		├── Faction
		├── Population
		├── Industries
		├── Imports
		├── Exports
		└── Market
```

The first procedural test system targets:

- [x] **5 planets** per generated test system
- [x] **3 stations** per generated test system
- [x] **7 factions**
- [x] Multiple planet types
- [x] Raw resources
- [x] Processed goods
- [x] Production recipes
- [x] Dynamic supply and demand data
- [x] Dynamic prices
- [x] Multiple star types
- [x] Planetary orbits
- [x] System map
- [x] Inter-system warp travel
- [x] In-system hyperdrive to stations
- [x] Hierarchical orbital simulation
- [x] Player inherits nearby planetary or station orbital velocity
- [x] Planetary moons
- [x] Procedural asteroid belts

---

# Space Simulation

The space simulation uses a hierarchical orbital model.

```text
Star
  ↓ gravity
Planets
  ↓ gravity
Moons
  ↓ gravity
Stations
```

The simulation currently provides:

- [x] Stable star-to-planet orbits
- [x] Planet-to-moon orbits
- [x] Planet-to-station orbits
- [x] Orbital periods derived from parent mass and orbital distance
- [x] Multiple moons per planet
- [x] Planets with no moons
- [x] Asteroid belts with independently orbiting asteroids
- [x] Player ship inherits the orbital velocity of nearby planets or stations

This is a **hierarchical Keplerian simulation**, rather than a full N-body physics simulation. The parent body's mass and orbital distance determine the orbital period, giving the system stable and predictable motion without requiring every object to calculate gravitational forces against every other object.

The player therefore does not sit motionless relative to the universe when stopped beside a planet. If the ship is stationary relative to that planet or its station, it travels through the star system with the same orbital motion.

# Planets

Planets are procedurally generated from data-defined planet types.

Current types:

- Barren
- Frozen
- Habitable
- Desert
- Ocean
- Volcanic
- Gas Giant
- Ice Giant

Generated properties include:

- Unique name
- Radius
- Gravity
- Temperature
- Atmosphere
- Population
- Resource availability
- Resource abundance

Gravity is intentionally part of the world data because eventually planetary environments should affect how ships behave.

For example, a large gas giant should not behave like a small barren moon.

---


---

# Ships and Equipment

Ships are split into ship templates and player-owned ship instances.

A `ShipData` resource is a catalogue/template definition. It describes the fixed architecture of a standard ship and is not modified by player equipment changes.

An `OwnedShipData` resource represents the actual ship the player owns. It stores installed equipment and persistent ship state.

```text
Ship Template
     │
     ▼
Owned Ship
├── Fixed Body
├── Fixed Wings
├── Fixed Tail
├── Installed Weapons
├── Installed Modules
├── Cargo
├── Current Hull
└── Current Shield
```

### Ship Construction

Standard ships are assembled from three fixed structural parts:

- **Body** determines hull points, armour and module slots.
- **Wings** determine weapon mounts and cargo capacity.
- **Tail** determines speed, acceleration and boost performance.

The player can customize equipment without modifying the underlying template.

### Ship Modules

Modules occupy slots provided by the ship body.

Current modules include:

- Basic Shield Generator
- Standard Shield Generator
- Reinforced Shield Generator
- Reinforced Armour
- Cargo Expansion
- Engine Booster
- Power Generator
- Scanner

Shield capacity is entirely module-based. A ship with no shield generator has zero shield capacity, and its shield bar is hidden.

### Ship Weapons

Ships support up to four weapon mounts depending on their wings.

Current weapon families include:

- Civilian Laser
- Pirate Laser
- Authority Laser
- Pulse Laser
- Beam Laser
- Plasma Cannon
- Autocannon
- Heavy Cannon
- Railgun
- Scatter Cannon
- Micro Missile Rack
- Standard Missile
- Heavy Torpedo

Standard ship templates have predefined starting loadouts, while owned ships are the player's customizable equipment state.

# Resources

Resources are raw materials extracted from planets and other locations.

Current resources:

| Resource | Use |
|---|---|
| Water | Life support, agriculture and industry |
| Hydrogen | Fuel production |
| Helium | Advanced industry |
| Iron Ore | Steel and manufacturing |
| Copper Ore | Electronics |
| Titanium Ore | Shipbuilding |
| Silicates | Construction and electronics |
| Carbon | Fuels and alloys |
| Uranium Ore | Specialised power |
| Rare Earths | Advanced electronics |
| Organic Matter | Food and medical production |
| Industrial Crystals | Sensors and advanced components |

Resources have:

- ID
- Name
- Description
- Base value
- Mass
- Category

---

# Goods

Goods are processed commodities produced by industries.

Current goods:

- Fuel
- Food
- Steel
- Electronics
- Machinery
- Fertilizer
- Ship Components
- Medical Supplies
- Construction Materials
- Advanced Components

Resources and goods are deliberately separate.

**Resources are extracted. Goods are manufactured.**

---

# Production

Production chains connect the economy.

Examples:

```text
Iron + Carbon
	  ↓
	Steel

Copper + Rare Earths + Crystals
	  ↓
  Electronics

Steel + Electronics
	  ↓
   Machinery

Hydrogen + Carbon
	  ↓
	 Fuel

Steel + Titanium + Electronics
	  ↓
 Ship Components
```

Production recipes contain:

- Inputs
- Input quantities
- Output
- Output quantity
- Production time

This allows shortages to propagate through the economy.

---

# Stations

Stations are generated from station types.

Current station types:

- Mining
- Agricultural
- Industrial
- Refinery
- Shipyard
- Research
- Trade Hub
- Military

A station has:

- Station type
- Faction
- Population
- Industries
- Resource imports
- Resource exports
- Good imports
- Good exports
- Production recipes
- Local market

Examples:

### Mining Station

Extracts:

- Iron
- Titanium
- Rare Earths

Needs:

- Food
- Water
- Fuel
- Machinery

### Industrial Station

Needs:

- Iron
- Copper
- Titanium
- Rare Earths
- Carbon
- Fuel

Produces:

- Steel
- Electronics
- Machinery
- Construction Materials

### Shipyard

Needs:

- Titanium
- Steel
- Electronics
- Fuel

Produces:

- Ship Components
- Advanced Components

---

# Factions

Current factions:

- Colonial Authority
- Frontier Coalition
- Helios Mining Consortium
- Orion Trade League
- Independent
- Sol System Authority (law enforcement)
- Red Knife Syndicate (bandits)

Factions can influence:

- Station ownership
- Preferred industries
- Preferred goods
- Territory
- Prices
- Security
- Reputation
- Missions

The faction system will remain simple until the underlying world simulation is working.

---

# Economy

The economy is intended to be a real simulation rather than a collection of static shop prices.

The basic flow is:

```text
PLANETS
   ↓
RESOURCES
   ↓
PRODUCTION
   ↓
GOODS
   ↓
STATIONS
   ↓
SUPPLY + DEMAND
   ↓
PRICES
   ↓
TRADE
   ↓
CHANGING SUPPLY
   ↓
CHANGING PRODUCTION
```

A station's price is influenced by:

- Base value
- Local supply
- Local demand
- Population
- Production
- Resource availability

Basic pricing pressure follows:

```text
High Supply + Low Demand  → Lower Price
Low Supply + High Demand  → Higher Price
```

The important part is the feedback loop.

If an industrial station runs short of copper:

```text
Copper shortage
	  ↓
Electronics production falls
	  ↓
Electronics supply falls
	  ↓
Electronics price rises
	  ↓
Trading copper becomes more attractive
	  ↓
Copper arrives
	  ↓
Electronics production recovers
```

That is the kind of world behaviour the project is aiming for.

---

# Procedural Generation

The procedural world is data-driven.

### Data

Defines what exists.

```text
data/
├── planets/
├── economy/
│   ├── resources/
│   ├── goods/
│   ├── recipes/
│   └── stations/
└── factions/
```

### Generators

Create the world.

```text
scripts/
├── planets/
│   └── planet_generator.gd
├── economy/
│   └── station_generator.gd
└── world/
	└── system_generator.gd
```

### Simulation

Handles changing state.

```text
scripts/economy/
└── market.gd
```

### Scenes

Display the generated world.

The generators should not create UI. Godot scenes remain responsible for presentation.

---

# Technical Architecture

```text
res://
├── assets/
│   ├── ships/
│   ├── enemies/
│   ├── planets/
│   ├── stations/
│   ├── characters/
│   ├── weapons/
│   ├── items/
│   ├── effects/
│   ├── environment/
│   ├── ui/
│   └── audio/
│
├── data/
│   ├── ships/
│   ├── enemies/
│   ├── planets/
│   ├── weapons/
│   ├── items/
│   ├── missions/
│   ├── factions/
│   └── economy/
│
├── scenes/
│   ├── main/
│   ├── player/
│   ├── enemies/
│   ├── planets/
│   ├── ships/
│   ├── stations/
│   ├── boarding/
│   ├── ui/
│   └── world/
│
└── scripts/
	├── player/
	├── enemies/
	├── planets/
	├── ships/
	├── managers/
	├── economy/
	├── missions/
	├── factions/
	├── boarding/
	├── ui/
	└── world/
```

### Architecture Rules

- Data resources describe the universe.
- Generators create generated world state.
- Simulation systems modify world state.
- Scenes display and interact with the world.
- Shared state stays small and understandable.
- UI is created through Godot scenes, not generated in scripts.
- Scripts use explicit variable types.
- Systems should be testable independently.
- Do not build a massive manager when a small domain system is enough.

---

# Development Roadmap

## Milestone 0 - Project Foundation

**Status: COMPLETE**

- [x] Godot project configuration
- [x] Folder architecture
- [x] Main scene
- [x] Scene manager
- [x] Input actions
- [x] Shared world state

---

## Milestone 1 - Space Combat Prototype

**Status: COMPLETE**

- [x] Space scene and camera
- [x] Star Valor-style WASD ship movement
- [x] Momentum and reverse movement
- [x] Boost
- [x] Boost feedback
- [x] Forward weapon
- [x] Projectiles
- [x] Enemy ship
- [x] Enemy movement and firing
- [x] Collision and damage
- [x] Shields and hull
- [x] Ship destruction
- [x] Salvage
- [x] Credits

**Completion result:**

**Fly → Boost → Fight → Destroy → Salvage → Earn Credits**

---

## Milestone 2 - First Station

**Status: COMPLETE**

- [x] Station scene
- [x] Docking interaction
- [x] Space-to-station transition
- [x] Top-down character movement
- [x] Docking bay
- [x] One NPC
- [x] One market terminal
- [x] Station-to-space return

**Completion result:**

**Fly → Dock → Leave Ship → Explore → Interact → Return to Space**

---

## Milestone 3 - Procedural World Foundation

**Status: COMPLETE**

### Data Definitions

- [x] Raw resource data
- [x] Trade good data
- [x] Production ingredient data
- [x] Production recipe data
- [x] Planet type data
- [x] Station type data
- [x] Faction data
- [x] Star data

### Initial Content

- [x] 12 raw resources
- [x] 10 processed goods
- [x] 10 production recipes
- [x] 8 planet types
- [x] 8 station types
- [x] 5 factions
- [x] Multiple star types

### Generation

- [x] Generated planet data
- [x] Planet generator
- [x] Generated station data
- [x] Station generator
- [x] Generated system data
- [x] System generator
- [x] Generate a complete test system in-game
- [x] Place generated planets in space
- [x] Place generated stations in space
- [x] Display generated names and types
- [x] Connect generated stations to their planets
- [x] Generate planetary orbits
- [x] Display orbital paths
- [x] Generate stars and display star properties
- [x] Generate 0 to 5 moons per planet
- [x] Generate asteroid belts

---

## Milestone 4 - Living Economy

- [x] Market data model
- [x] Initial supply
- [x] Initial demand
- [x] Dynamic price calculation
- [ ] Production simulation
- [ ] Consumption simulation
- [ ] Supply changes over time
- [ ] Demand changes over time
- [ ] Production shortages
- [ ] Price feedback
- [ ] Player trading
- [ ] Cargo inventory integration
- [ ] Economy persistence

**Completion test:**

A player should be able to discover a price difference between two stations, trade a commodity, and change the local market by doing so.

---


---

## Milestone 5 - Ship Equipment and Progression

**Status: IN PROGRESS**

- [x] Ship body data
- [x] Ship wings data
- [x] Ship tail data
- [x] Ship module data
- [x] Ship weapon data
- [x] Standard ship templates
- [x] Weapon mount limits
- [x] Weapon loadouts
- [x] Player-owned ship data
- [x] Separate ship templates from owned ship state
- [x] Modular shield generators
- [x] Persistent owned ship through scene transitions
- [ ] Shipyard equipment interface
- [ ] Install/remove modules from owned ships
- [ ] Install/remove weapons from owned ships
- [ ] Weapon tiers
- [ ] Weapon manufacturers/faction variants
- [ ] Equipment purchasing
- [ ] Equipment inventory
- [ ] Ship buying and selling
- [ ] Custom body/wings/tail ship construction

The structural parts of a standard ship remain fixed. Custom ships will eventually allow the player to select compatible body, wings and tail parts.

## Milestone 6 - Missions and Rewards

- [ ] Mission data resource
- [ ] Mission manager
- [ ] Mission acceptance
- [ ] Delivery mission
- [ ] Combat mission
- [ ] Salvage mission
- [ ] Mission completion
- [ ] Mission failure
- [ ] Credits reward
- [ ] Reputation changes

Missions should use the existing world rather than creating fake mission-only locations and commodities.

---

## Milestone 7 - Ship Boarding

- [ ] Boarding requirement
- [ ] Boarding transition
- [ ] Small ship interior
- [ ] On-foot enemy
- [ ] Boarding objective
- [ ] Cargo interaction
- [ ] Extraction point
- [ ] Return to space
- [ ] Apply boarding results

---

## Milestone 8 - Expanded Stations

- [ ] Shipyard
- [ ] Trade market
- [ ] Equipment vendor
- [ ] Mission office
- [ ] Multiple NPCs
- [ ] Station visual identities
- [ ] Station services

---

## Milestone 9 - Multiple Systems

**Status: IN PROGRESS**

- [x] Multiple star systems
- [x] System travel
- [ ] Jump routes
- [ ] System-specific economies
- [x] System map
- [ ] Unlockable destinations
- [ ] Inter-system trade

---

## Milestone 10 - Deeper RPG Systems

- [ ] Character equipment
- [ ] On-foot weapons
- [ ] Armour
- [ ] Consumables
- [ ] Boarding hazards
- [ ] More boarding objectives
- [ ] Ship upgrades
- [ ] Reputation consequences
- [ ] Faction relationships

---

## Milestone 11 - Polish

- [ ] Balance ships
- [ ] Balance weapons
- [ ] Balance economy
- [ ] Improve combat feedback
- [ ] Improve station visuals
- [ ] Add audio
- [ ] Improve HUD
- [ ] Save/load polish
- [ ] Optimization
- [ ] Release testing

---

# MVP

The first real MVP should prove that the **world itself is fun to move through**.

It should contain:

- One generated star system
- Several generated planets
- Several generated stations
- Multiple factions
- Resources
- Production
- Goods
- Markets
- Dynamic prices
- One controllable ship
- Space combat
- Salvage
- Station exploration
- Basic trading
- One or two meaningful missions
- One boarding scenario

### The MVP Question

> **Does travelling through the world, interacting with its economy and getting into trouble create a fun loop before we add a giant story?**

If not, improve the systems that already exist before adding more content.

---

# Current Status

**Current Stage: Milestones 4 and 5 - Living Economy and Ship Equipment**

Milestones 0, 1, 2 and 3 are complete. Milestones 4 and 5 are currently in progress.

The project now has the first layer of the world simulation:

```text
Planet Types
	 ↓
Generated Planets
	 ↓
Resources

Station Types
	 ↓
Generated Stations
	 ↓
Factions
	 ↓
Markets

Resources
	 ↓
Production Recipes
	 ↓
Goods
	 ↓
Supply + Demand
	 ↓
Prices
```

### Immediate Next Steps

1. Complete production and consumption simulation.
2. Connect supply and demand changes to the economy.
3. Implement real player cargo trading.
4. Build the ship equipment/shipyard fitting flow around `OwnedShipData`.
5. Add weapon tiers and meaningful equipment progression.
6. Connect equipment purchases to the economy.
7. Build missions on top of the working world simulation.

---

# Long-Term Possibilities

These remain intentionally outside the current prototype:

- Multiple star systems
- Dynamic faction territories
- Smuggling
- Bounty hunting
- Ship capture
- Player-owned stations
- Crew
- Fleet encounters
- Advanced ship interiors
- Procedural encounters
- Large-scale supply chains
- Multiplayer

The long-term vision can be ambitious.

The implementation should stay small enough to finish.
