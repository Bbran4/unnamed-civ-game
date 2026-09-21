# Untitled Space RPG

A top-down 2D spacefaring action RPG inspired by the freedom and progression of classic space-trading games, with the added ability to leave the cockpit, explore stations and board other ships.

The player is a pilot, traveller and opportunist. They can fight in space, travel between star systems, trade goods, gather salvage, accept missions, upgrade ships and equipment, explore stations on foot, and board hostile or disabled ships for contained ground encounters.

The game uses a **hybrid world structure**. Space areas, stations, planetary locations and ship interiors are connected through transitions rather than requiring one fully seamless map. This keeps the project achievable while preserving the feeling of an interconnected world.

## Core Identity

**Top-down 2D action RPG + twin-stick space combat + explorable stations + ship boarding.**

### Gameplay Modes

- **Space Mode:** Fly ships, fight enemies, travel, trade, salvage and interact with other vessels.
- **Ground Mode:** Leave the ship, explore stations and ship interiors, speak to NPCs, accept missions, shop and fight on foot when necessary.

The ship should feel like both a vehicle and a home. Stations and boarded ships should provide places where stories, danger and opportunities unfold.

## Design Pillars

1. Give the player freedom to fight, trade, explore, salvage or complete missions.
2. Make the world enterable. The player is not permanently attached to the cockpit.
3. Use meaningful progression across ships, character equipment, cargo and reputation.
4. Keep combat active and understandable. Progression should improve capability without removing player agency.
5. Build the smallest convincing version first. Do not build a universe before proving the core loop.
6. Every completed milestone must leave the project playable.

## Core Gameplay Loop

**Undock → Travel → Discover or Accept a Mission → Fight, Trade, Salvage or Explore → Return to a Station → Sell, Repair and Upgrade → Prepare for the Next Journey**

A longer-term loop may include:

**Receive Mission → Travel to Target → Fight or Board a Ship → Complete Objective → Escape or Return → Receive Payment → Upgrade Ship and Character → Unlock New Opportunities**

## World Structure

```text
Star System
├── Space Map
│   ├── Player Ship
│   ├── Enemy and Civilian Ships
│   ├── Cargo and Salvage
│   ├── Travel Points
│   └── Docking and Boarding Interactions
├── Orbital Station
│   ├── Mission Office
│   ├── Shipyard
│   ├── Trade Market
│   ├── Equipment Vendor
│   ├── Social Area
│   └── Docking Bay
├── Planetary Location
│   ├── Landing Area
│   ├── NPCs and Services
│   └── Missions and Activities
└── Ship Interiors
	├── Player Ship
	├── Friendly Ships
	└── Hostile or Disabled Ships
```

Actions should persist between modes. Examples include stolen cargo entering the inventory, ship damage remaining until repaired, purchases persisting after departure, and mission results updating shared world state.

## Space Combat

Space combat uses a **twin-stick control scheme**.

| Input | Action |
|---|---|
| WASD / Left Stick | Move or thrust |
| Mouse / Right Stick | Aim weapons |
| Left Mouse Button / Right Trigger | Fire primary weapon |
| Right Mouse Button / Left Trigger | Secondary weapon or ability |
| Space / Button | Boost or evade |
| E / Button | Interact, dock or begin boarding |
| Tab | Cycle targets or view target information |
| Esc | Pause or open the system menu |

The initial movement model should be arcade-based. A hybrid momentum model can be tested later if it improves combat without making basic movement frustrating.

### Initial Ship Systems

- Hull health
- Optional shields or armour
- Primary weapon
- Secondary weapon or special ability
- Movement and aiming
- Damage and destruction or disabling
- Cargo capacity
- Repair cost
- Ship ownership and identification

Targeted components such as engines, weapons, cargo holds and power systems should be added only after basic combat is stable.

### First Enemy

The first enemy should be able to detect the player, approach or maintain combat distance, aim and fire, take damage, retreat or become disabled, and drop salvage or a mission item.

## Stations and On-Foot Exploration

Stations are safe or semi-safe hubs where the player can interact with the world outside the cockpit.

| Location | Purpose |
|---|---|
| Mission Office | Accept contracts, quests and faction work |
| Shipyard | Buy, sell, repair and upgrade ships |
| Trade Market | Buy and sell goods and resources |
| Equipment Vendor | Purchase weapons, armour, tools and consumables |
| Social Area | Meet NPCs, discover rumours and access dialogue |
| Docking Bay | Enter and leave the player's ship |

### Initial Ground Mechanics

- Top-down character movement
- Interaction prompts
- One NPC or mission terminal
- Basic dialogue or interaction
- Shop interface
- Health and damage
- Simple ranged weapon
- Station and ship-interior transitions
- Return to the player's ship

On-foot gameplay is initially a supporting layer, not a second full-scale RPG. It should add variety and meaningful objectives without multiplying the project's scope.

## Ship Boarding

Boarding is one of the defining features of the project. The early implementation should use a **separate interior map** loaded through a boarding transition. Seamless boarding can be evaluated later.

### Boarding Flow

```text
Encounter Ship
→ Disable or Meet Boarding Requirement
→ Initiate Boarding
→ Load Ship Interior
→ Complete Objective
→ Extract
→ Return to Space
→ Apply Mission and World-State Changes
```

### Boarding Mission Types

- **Cargo Theft:** Locate marked cargo and escape.
- **Sabotage:** Reach a system and disable it.
- **Rescue:** Find and escort an NPC to extraction.
- **Capture:** Secure a target or hold a location.
- **Technology Recovery:** Retrieve a specific item.
- **Inspection:** Investigate a ship without necessarily destroying it.

The first boarding prototype should contain one small interior, one enemy type, one clear objective and a reliable extraction flow.

## Missions

Missions connect combat, travel, stations, boarding and progression.

| Mission | Core Activity |
|---|---|
| Cargo Delivery | Deliver goods to a destination |
| Pirate Interception | Locate and defeat a hostile ship |
| Salvage Recovery | Recover cargo or wreckage |
| Emergency Rescue | Rescue an NPC |
| Boarding Contract | Complete an interior objective |
| Escort | Protect a travelling ship |
| Investigation | Visit locations and collect information |

Mission data may include title, description, issuer, destination, objective, requirements, reward, failure conditions and follow-up consequences.

## Economy and Progression

The initial economy should remain small and understandable:

- Credits
- Cargo items
- Salvage
- Repair costs
- Ship and weapon costs
- Mission rewards

### Ship Progression

- Hull durability
- Shields or armour
- Weapon damage and fire rate
- Movement and handling
- Cargo capacity
- Utility slots
- Special abilities
- Ship class and size

### Character Progression

- Health
- On-foot weapons
- Armour
- Inventory capacity
- Boarding abilities
- Utility tools
- Dialogue or mission access

### World Progression

- Credits
- Faction reputation
- New systems and destinations
- Better shops and missions
- Ship and equipment ownership
- Unlockable services

Ownership and usability may be separate. A player can potentially purchase an item before meeting the requirements to use it effectively.

## Technical Architecture

The project is organized by game domain so new systems have a predictable home without forcing everything into one large manager or script.

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
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── planets/
│   ├── ships/
│   ├── managers/
│   ├── economy/
│   ├── missions/
│   ├── boarding/
│   ├── ui/
│   └── world/
│
└── README.md
```

### Folder Responsibilities

| Folder | Purpose |
|---|---|
| `assets/` | Visuals, audio, effects and other imported game assets |
| `data/` | Game definitions and configuration such as ships, weapons, missions and economy data |
| `scenes/` | Godot scenes grouped by gameplay domain |
| `scripts/` | Gameplay and system logic grouped by gameplay domain |
| `scripts/managers/` | Cross-system managers such as scene, mission and save management |

The structure is deliberately prepared before gameplay implementation. Empty directories are kept in Git with placeholder files and will be replaced as real content is added.

Space combat, ground exploration, boarding and progression should remain separate systems connected through shared world state.

## Development Roadmap

### Milestone 0 - Project Foundation

**Status: IN PROGRESS**

- [x] Confirm Godot version and project settings
- [x] Create clean project structure
- [x] Establish main scene and scene manager
- [x] Configure input actions
- [ ] Confirm reliable project launch
- [x] Create basic shared world state

**Foundation implemented:** The project now has a main scene, centralized scene transitions, persistent shared world state, and the initial keyboard/mouse input actions.

**Launch verification:** A GitHub Actions validation workflow has been added to check the project with Godot 4.7.2 and launch the main scene headlessly. Milestone 0 remains incomplete until that launch check passes.

### Milestone 1 - Twin-Stick Space Combat

**Status: NEXT**

**Goal:** Prove that flying and fighting are enjoyable.

- [ ] Space scene and camera
- [ ] Player ship movement
- [ ] Mouse or right-stick aiming
- [ ] Primary weapon and projectiles
- [ ] One enemy ship
- [ ] Enemy movement and firing
- [ ] Collision and damage
- [ ] Ship destruction or disabling
- [ ] Combat feedback
- [ ] Salvage or reward drop

**Completion test:** The player can enter space, fight an enemy and immediately understand the combat.

### Milestone 2 - Docking and First Station

- [ ] Station scene
- [ ] Docking interaction
- [ ] Space-to-station transition
- [ ] Top-down character movement
- [ ] Docking bay
- [ ] One NPC
- [ ] One shop or mission terminal
- [ ] Station-to-space return

**Completion test:** The player can fly to a station, leave the ship, walk around, interact and return to space.

### Milestone 3 - Missions and Rewards

- [ ] Mission data resource
- [ ] Mission manager
- [ ] Mission acceptance
- [ ] One delivery or combat mission
- [ ] Completion and failure states
- [ ] Credits reward
- [ ] Mission status UI

### Milestone 4 - First Boarding Mission

- [ ] Boarding requirement or interaction
- [ ] Boarding transition
- [ ] Small ship interior
- [ ] One on-foot enemy
- [ ] One boarding objective
- [ ] Cargo or item interaction
- [ ] Extraction point
- [ ] Return to space
- [ ] Apply results to world state

**Recommended first mission:** Disable an enemy ship, board it, steal marked cargo and escape.

### Milestone 5 - Basic Economy and Progression

- [ ] Credits display
- [ ] Cargo inventory
- [ ] Salvage rewards
- [ ] Ship repair costs
- [ ] First weapon upgrade
- [ ] Hull or cargo upgrade
- [ ] Shop purchasing
- [ ] Save and load progression
- [ ] Balance rewards and costs

### Milestone 6 - Expanded Stations

- [ ] Shipyard
- [ ] Trade market
- [ ] Equipment vendor
- [ ] Mission office
- [ ] Multiple NPCs
- [ ] Station identity and visual differentiation

### Milestone 7 - More Content

- [ ] Additional player ships
- [ ] Additional enemy types
- [ ] Delivery, salvage, rescue and escort missions
- [ ] Boarding variations
- [ ] Faction relationships

### Milestone 8 - Star Systems and Travel

- [ ] Star system structure
- [ ] Travel points or jump routes
- [ ] Multiple stations or planetary locations
- [ ] System-specific encounters
- [ ] Basic map interface
- [ ] Unlockable destinations

### Milestone 9 - Deeper RPG and Boarding Systems

- [ ] Character equipment
- [ ] On-foot weapon variety
- [ ] Armour and consumables
- [ ] Boarding hazards
- [ ] Advanced ship interiors
- [ ] Capture, rescue and sabotage variations
- [ ] Reputation consequences

### Milestone 10 - Balance and Release Polish

- [ ] Balance ships, weapons, missions and repairs
- [ ] Improve combat feedback
- [ ] Improve station and interior visuals
- [ ] Add audio and music
- [ ] Improve HUD and menus
- [ ] Finalize saving and migration handling
- [ ] Test fresh and long-term progression
- [ ] Optimize and fix release bugs

## MVP

The first MVP is a vertical slice, not the complete space RPG.

It should contain:

- One space area
- One controllable ship
- Twin-stick movement and aiming
- One enemy ship
- Basic space combat
- One station
- One playable character
- Station movement and interaction
- One NPC or mission terminal
- One mission
- One simple shop
- One small ship interior
- One on-foot enemy
- One boarding objective
- Basic credits and one upgrade

### The MVP Question

> **Does moving between space combat, stations and boarding create a fun gameplay loop?**

If not, improve the existing experience before adding more systems, factions, ships or crafting.

## Development Rules

1. Build one milestone at a time.
2. Keep the first playable version small enough to finish.
3. Do not build a complete universe before proving the core loop.
4. Prefer separate boarding interiors during early development.
5. Keep systems modular without creating unnecessary abstractions.
6. Introduce one new system at a time and test it in the playable build.
7. Avoid large content pipelines before mechanics are stable.
8. Use placeholder art to prove gameplay, then replace it deliberately.
9. Progression should improve options without making the game play itself.
10. Every milestone must leave the project playable.
11. Do not add crafting, complex factions, procedural generation or multiplayer until the core single-player loop is reliable.
12. Keep shared world state small and understandable.
13. Design missions around actions that exist in the current build.
14. When a feature becomes repetitive work, reduce its scope and test a smaller version rather than abandoning the whole project.
15. The README is a living roadmap. Playtesting can change the design.
16. Every feature must justify its complexity by improving the player's experience.

## Current Status

**Current Stage: Milestone 0 - Project Foundation**

The foundation is being implemented directly in the repository. The remaining Milestone 0 requirement is to verify that Godot can launch the configured main scene successfully.

### Immediate Next Steps

- [ ] Verify the Godot project launches successfully
- [ ] Confirm the validation workflow passes
- [ ] Then begin Milestone 1: Twin-Stick Space Combat

## Long-Term Possibilities

These ideas are outside the first MVP:

- Multiple factions and reputation
- Dynamic economy and supply chains
- Ship capture and ownership
- Procedural or semi-procedural star systems
- Crew members and ship roles
- Persistent ship interiors and damage
- Smuggling and illegal goods
- Bounty hunting
- Fleet encounters
- Crafting and resource processing
- Player-owned stations or businesses
- More complex character progression
- Multiplayer or cooperative play

The long-term vision can be ambitious. The development process must remain small, testable and finishable.
