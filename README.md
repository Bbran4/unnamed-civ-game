# Unnamed Space Game

A **3D single-player space detective game** inspired by Freelancer, built in **Godot 4.x with GDScript**.

You are a space cop investigating a series of murders across the galaxy. Fly between systems, dock at orbital stations, take space elevators down to planetary surfaces, board frigates, gather clues, and uncover a conspiracy.

> **Fly anywhere. Follow the evidence. Make your own reputation.**

---

# Core Vision

The player is a space detective.

The main fantasy is investigation across a living galaxy:

- Fly freely between star systems and planets.
- Dock at orbital stations.
- Take a space elevator down to the surface to investigate crime scenes, interview suspects and follow leads.
- Board frigates and other large vessels to search for clues.
- Meet allies (including a petty criminal who assists on cases).
- Uncover a larger conspiracy.

Space flight, combat and stations come first. Story and deep investigation systems come after the space layer feels excellent.

---

# Design Pillars

1. **Flying is the foundation.** Space combat and navigation must be fun before anything else is added.
2. **Space must feel solid.** Planets are large, beautiful and impassable. Ships cannot fly through them.
3. **Investigation is the spine.** Cases, clues, suspects and conspiracies give the player a reason to travel.
4. **Stations are the hubs.** Almost all social, shopping and case-management activity happens at orbital stations or on the surface via elevator.
5. **Boarding matters.** Frigates and large ships can be entered (via docking-bay transition) to search for evidence.
6. **Build vertically first.** One excellent playable system is more valuable than twenty unfinished systems.
7. **Keep it finishable.** Simulation depth should serve gameplay, not become the project.

---

# Core Gameplay Loop

```text
Leave station
	↓
Travel to a system / planet / lead
	↓
Fly through space
	↓
Fight, scan, or avoid threats
	↓
Dock at orbital station
	↓
Talk / buy / accept or advance a case
	↓
Take space elevator to surface (if needed)
	↓
Investigate crime scene / interview / gather clues
	↓
Return to station → undock
	↓
Follow the next lead
```

A typical session might become:

```text
Receive case brief
	↓
Fly to the system where the body was found
	↓
Dock at the orbital station
	↓
Interview station security
	↓
Take elevator to the surface colony
	↓
Examine the crime scene
	↓
Find a lead pointing to a freighter
	↓
Return to space
	↓
Locate and board the freighter
	↓
Discover evidence of a wider conspiracy
	↓
Return to station to report and upgrade
```

---

# World Structure

```text
Galaxy
 ├── Sector
 │    ├── Star System
 │    │    ├── Planet (large visual object + solid collision)
 │    │    ├── Orbital Station (docking + elevator to surface)
 │    │    ├── Asteroid Field
 │    │    ├── Trade Route
 │    │    └── Hidden Location
 │    └── ...
 └── ...
```

Planets are **not** landable by ship. They are large, static, beautiful objects in space with solid collision so ships cannot fly through them.

Surface access is always:

```text
Space → Dock at orbital station → Space elevator → Surface location
```

---

# Planets

Planets must feel large and real.

Requirements:

- High-quality surface textures, clouds and atmosphere.
- Solid collision (StaticBody3D + SphereShape3D) so ships cannot pass through.
- Optional soft exclusion / warning zone around the planet so dogfights do not end with ships slamming into the surface.
- No ship landing on the planet itself.

The player never flies into the atmosphere or lands the ship on the ground. The planet is pure set dressing + barrier, exactly like classic Freelancer, with modern visuals.

### Preventing ships from flying into planets

1. Hard collision sphere matching the visual planet.
2. Slightly larger Area3D that detects ships entering the planetary exclusion zone.
3. The exclusion signal can later drive HUD warnings, scanner feedback and a gentle outward safety force.
4. This applies to both the player and AI ships, so combat near planets cannot turn into accidental planet clipping.

This must work during normal flight and during combat.

---

# Stations and Surface Access

Stations are the primary hubs.

```text
SPACE
  ↓
DOCKING
  ↓
STATION INTERIOR
  ↓
SPACE ELEVATOR (optional)
  ↓
SURFACE LOCATION (crime scene, colony, lab, etc.)
```

At a station the player can:

- Repair and rearm.
- Buy and sell goods / equipment.
- Accept or advance cases.
- Talk to NPCs and informants.
- Access terminals and evidence boards.
- Take the space elevator down to the surface.
- Save.

Surface locations are focused third-person areas used for investigation. They are not open-world planetary surfaces.

---

# Boarding Frigates and Large Ships

Large vessels (frigates, freighters, etc.) can be boarded.

When the player flies into a docking bay:

- A portal / scene transition loads the interior of the frigate.
- The player can walk the interior in third person, search for clues, confront crew, etc.
- Leaving through the docking bay returns the player to space and unloads the interior scene.

This keeps frigate interiors manageable while still feeling like the player physically entered the ship.

Boarding disabled enemy ships for combat or evidence remains a separate (later) system.

---

# Space Flight

Space flight is the foundation of the game.

The player controls a 3D spacecraft using an accessible **twin-stick-inspired control scheme**. The mouse cursor is free to move around the screen, and the ship smoothly steers toward the cursor.

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

## Flight Model

Flight characteristics are **direct gameplay values**, tuned per ship.

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

Throttle and velocity are separate. Releasing W maintains current speed. Space applies braking thrust. Turning does not automatically redirect existing velocity.

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

Other states: Disabled, Boarding, Jumping, Salvaging, Destroyed.

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

Initial systems: energy weapons, projectiles, missiles, shields, hull, targeting, energy, countermeasures, destruction.

Later: subsystem targeting, disabled ships, boarding opportunities.

---

# Ships

The player will have access to several usable spacecraft.

Ships are modular:

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

Example classes: Fighter, Gunship, Explorer, Utility / Investigation craft.

A landable / boardable frigate is a longer-term goal (docking-bay portal into an interior scene).

---

# Investigation (High-Level)

The long-term spine of the game is investigation.

- Cases with crime scenes, evidence, suspects and leads.
- Surface locations reached via space elevator.
- Frigate interiors reached via docking-bay transition.
- Allies (including a petty criminal who helps on cases).
- A larger conspiracy that the player slowly uncovers.

Detailed case systems, dialogue and evidence boards come after the space layer is solid.

---

# Current Priority

**Make space work perfectly.**

Immediate focus:

1. Beautiful, solid planets (visuals + collision + exclusion zone).
2. Reliable docking at orbital stations.
3. Clean flight and combat feel (already largely in place).
4. Multiple player-usable spacecraft.
5. Basic station interior as a hub.

Only after space, stations and planets feel excellent do we expand into elevators, surface investigation scenes and frigate interiors.

---

# Technical Direction

## Engine
**Godot 4.x**

## Language
**GDScript**

## Rendering
**3D** — readable, stylised visuals preferred over photorealism.

## Planet Implementation

```text
Planet (Node3D)
├── MeshInstance3D (surface)
├── MeshInstance3D (clouds)
├── MeshInstance3D (atmosphere)
├── StaticBody3D
│   └── CollisionShape3D (SphereShape3D)
└── Area3D (exclusion / warning zone)
	└── CollisionShape3D (slightly larger sphere)
```

---

# Development Roadmap (Revised)

## Milestone 1–3
**Status: largely complete**
Reusable ship, flight model, combat, targeting, HUD, basic AI.

## Milestone 4 - Solid Space & Planets (CURRENT FOCUS)
- [ ] High-quality planet visuals (surface, clouds, atmosphere)
- [x] Solid planet collision (ships cannot fly through)
- [x] Planetary exclusion detection zone
- [ ] Exclusion warning / safety response
- [ ] Multiple player spacecraft
- [ ] Reliable docking at a simple orbital station
- [ ] Station interior as a basic hub
- [ ] Clean save / load around docked state

**Definition of done:** The player can fly around a beautiful solid planet, fight near it without clipping through, dock at a station, undock, and switch between a few ships.

## Milestone 5 - Station Hub
- Repair, equipment shop, basic case board, save point, NPC talk.

## Milestone 6 - Space Elevator & First Surface Location
- Elevator transition from station to a focused surface crime-scene area.
- Basic investigation interactions (examine, pick up clue, talk).

## Milestone 7 - Frigate Boarding
- Docking-bay portal into a frigate interior scene.
- Search for clues / confront crew / leave back to space.

## Milestone 8+
Cases, evidence, allies, conspiracy, more systems, economy, factions, etc.

---

# Architecture Notes

Keep the existing separation:

- ShipData / runtime Ship
- Controllers (Player / Enemy)
- Weapons, projectiles, damage, targeting
- Data-driven resources

Do not rebuild the flight or combat foundation. Extend it.

---

# Development Rules

- Build vertically before horizontally.
- Prototype with simple assets until the feel is right.
- Every major system must answer: “What does this let the player do?”
- Space must feel excellent before investigation systems expand.

---

# Current Status

Early prototype with working flight and combat.

**Next goal:** Beautiful solid planets + reliable station docking so the detective fantasy has a real space stage to play on.

The longer-term fantasy:

> Fly across the galaxy, dock at stations, ride elevators to crime scenes, board frigates, gather evidence with the help of unlikely allies, and uncover the conspiracy.
