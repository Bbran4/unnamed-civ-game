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

The player should feel like they are moving through a place that exists independently of whatever mission they currently have.

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
| Tab | Target |
| Esc | Pause / menu |

An alternate mouse-aim control style exists for testing.

### Initial Ship Systems

- Hull
- Shields
- Shield regeneration
- Acceleration
- Maximum speed
- Reverse movement
- Boost
- Primary weapon
- Projectiles
- Damage and destruction
- Salvage
- Credits

The combat model should remain arcade-like and responsive. More detailed ship systems can be added only when they improve the game.

---

# Stations and On-Foot Exploration

Stations are physical locations rather than menus.

The player can:

- Dock with a station
- Leave the ship
- Walk around
- Talk to NPCs
- Use terminals
- Visit markets
- Return to the ship
- Launch back into space

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

- **5 planets**
- **3 stations**
- **5 factions**
- Multiple planet types
- Raw resources
- Processed goods
- Production recipes
- Dynamic supply and demand
- Dynamic prices

---

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

**Status: IN PROGRESS**

### Data Definitions

- [x] Raw resource data
- [x] Trade good data
- [x] Production ingredient data
- [x] Production recipe data
- [x] Planet type data
- [x] Station type data
- [x] Faction data

### Initial Content

- [x] 12 raw resources
- [x] 10 processed goods
- [x] 10 production recipes
- [x] 8 planet types
- [x] 8 station types
- [x] 5 factions

### Generation

- [x] Generated planet data
- [x] Planet generator
- [x] Generated station data
- [x] Station generator
- [x] Generated system data
- [x] System generator
- [ ] Generate a complete test system in-game
- [ ] Place generated planets in space
- [ ] Place generated stations in space
- [ ] Display generated names and types
- [ ] Connect generated stations to their planets

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

## Milestone 5 - Missions and Rewards

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

## Milestone 6 - Ship Boarding

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

## Milestone 7 - Expanded Stations

- [ ] Shipyard
- [ ] Trade market
- [ ] Equipment vendor
- [ ] Mission office
- [ ] Multiple NPCs
- [ ] Station visual identities
- [ ] Station services

---

## Milestone 8 - Multiple Systems

- [ ] Multiple star systems
- [ ] System travel
- [ ] Jump routes
- [ ] System-specific economies
- [ ] System map
- [ ] Unlockable destinations
- [ ] Inter-system trade

---

## Milestone 9 - Deeper RPG Systems

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

## Milestone 10 - Polish

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

**Current Stage: Milestone 3 - Procedural World Foundation**

Milestones 0, 1 and 2 are complete.

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

1. Generate one complete test system.
2. Inspect the generated planets and stations.
3. Place the generated world into the existing space scene.
4. Give stations real markets.
5. Simulate production and consumption.
6. Let the player buy and sell cargo.
7. Only then start building missions on top of the simulation.

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
