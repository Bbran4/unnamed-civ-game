# Unnamed Civilization Game

A persistent-world civilization idle/strategy game where the player acts as a **guiding god** rather than a traditional ruler.

Civilizations gather resources, grow their populations, expand, discover technologies, trade, form alliances and fight wars largely on their own. The player's role is to give them direction by deciding what to build, what knowledge to pursue and when to begin a new era.

The world persists between civilizations. Ancient roads, cities, monuments, ruins and other changes can remain for future civilizations to discover and use.

> **Build a civilization. Shape a world. Leave a legacy.**

---

# Core Identity

The game combines:

- **Idle progression** - civilizations gather, grow and develop automatically.
- **God-game guidance** - the player influences priorities rather than micromanaging individual citizens.
- **Roguelite progression** - civilizations eventually reset, while permanent knowledge and legacy bonuses carry forward.
- **Civilization simulation** - independent AI civilizations develop at their own pace.
- **Persistent procedural world** - the map is generated once and remains the same across every era.
- **Emergent history** - civilizations can trade, cooperate, compete and go to war, creating a history that is different in every world.

The goal is not to build one perfect civilization. The goal is to create an increasingly developed world and watch history unfold across many civilizations.

---

# Design Pillars

1. **The civilization lives without the player.** Citizens gather resources, reproduce, explore, build and make decisions automatically.
2. **The player is a guide, not a micromanager.** The player chooses priorities and unlocks opportunities; the civilization handles the details.
3. **The world persists.** Geography, settlements, monuments, roads and ruins can survive across eras.
4. **Progression unlocks possibilities, not just bigger numbers.** Fishing should create new ways to live, not simply provide +10% food.
5. **AI civilizations are part of the world.** They should develop, trade, ally, compete and fight without requiring player involvement.
6. **Every era should leave something behind.** A civilization's achievements should matter after it is gone.
7. **Keep the core understandable.** The simulation can be deep, but the player's decisions should remain clear.
8. **Keep the project finishable.** Build a convincing small civilization simulation before expanding its scope.

---

# Core Gameplay Loop

The primary loop is:

**Observe → Choose a direction → Build → Civilization develops → Unlock knowledge → Leave a legacy → Begin a new era → Return to the same world**

A typical early game might look like:

```text
Settlers arrive
      ↓
Build Fire Pit
      ↓
Population begins growing
      ↓
Build House
      ↓
Population growth increases
      ↓
Build more infrastructure
      ↓
Generate Research Points
      ↓
Unlock new technology
      ↓
Civilization expands
      ↓
Player chooses when to begin a new era
      ↓
New civilization starts with inherited knowledge
```

The player does not directly command every citizen. The civilization interprets the player's choices and acts on them automatically.

---

# The Player as a God

The player's role is deliberately indirect.

You do not tell individual citizens:

> "Bob, go cut down that tree."

Instead, you tell the civilization:

> **"Build a Lumber Camp."**

The citizens decide who constructs it, gather the required materials and complete the building themselves.

The player provides **direction and opportunity**. The civilization provides the labour.

This should make the world feel alive even when the player is doing very little.

---

# Buildings

Buildings are the primary way the player influences the civilization.

A civilization begins with only a few basic options.

### Fire Pit

The first settlement structure.

Example effects:

- Improves gathering efficiency.
- Provides an initial population-growth bonus.
- Acts as the centre of the settlement.

### House

Provides shelter and increases population growth.

The player can select the House action repeatedly to encourage further housing development. The civilization automatically determines suitable locations and constructs the buildings.

Example progression:

```text
House I   → +5% population growth
House II  → +10% population growth
House III → +15% population growth
```

The exact values are subject to balancing.

Other planned buildings include:

- Lumber Camp
- Quarry
- Farm
- Fishing Camp
- Storage Hut
- Workshop
- Research Centre
- Mine
- Market
- Barracks
- Harbour
- Monument
- Road
- Temple
- Government buildings

Buildings should change how the civilization behaves, not simply increase an income number.

---

# Autonomous Civilization Simulation

The player's civilization should continue functioning without direct input.

Citizens can automatically:

- Gather food.
- Gather wood.
- Gather stone and other resources.
- Construct player-selected buildings.
- Find suitable places to settle.
- Grow the population.
- Explore nearby territory.
- Use available technologies.
- Establish trade.
- Defend the civilization.
- Expand into new territory.

The player acts as a high-level decision maker while the simulation handles individual citizens.

The intended feeling is:

> **"I gave them the tools. Now let's see what they do with them."**

---

# Resources and Idle Production

Resources are gathered automatically by the civilization.

Early resources may include:

- Food
- Wood
- Stone
- Water

Later technologies can introduce resources such as:

- Iron
- Coal
- Copper
- Gold
- Fertile Land
- Fish
- Livestock
- Luxury goods
- Strategic resources

Production is intentionally idle in nature. Once the civilization has access to a resource or production method, it continues operating automatically.

The player's main decisions are therefore about **what production to enable and how to develop it**, rather than manually clicking every resource.

---

# Population

Population is one of the most important resources in the simulation.

Population growth is affected by factors such as:

- Housing
- Food availability
- Water
- Health
- Technology
- Civilization traits
- Buildings
- Events

Population provides the workforce needed to support the civilization.

As the civilization grows, it can support increasingly specialised roles such as:

- Farmers
- Gatherers
- Builders
- Miners
- Researchers
- Merchants
- Soldiers
- Explorers

The exact workforce allocation should be handled primarily by the civilization AI rather than by constant player micromanagement.

---

# Research and Technology

Research is the long-term progression system.

Civilizations generate **Research Points** through development, population, buildings, discoveries and other achievements.

Research unlocks new capabilities.

Early technologies might include:

```text
Fire
 ├── Basic Shelter
 └── Cooking

Agriculture
 ├── Farming
 └── Animal Husbandry

Fishing
 ├── Fishing Camps
 └── Boats

Stoneworking
 ├── Stone Buildings
 └── Monuments
```

Later technologies can progress toward:

- Writing
- Mathematics
- Mining
- Metallurgy
- Sailing
- Engineering
- Trade
- Government
- Astronomy
- Industry
- Electricity
- Modern technology

Technology should provide **new options** as well as efficiency improvements.

For example:

> **Fishing** does not simply mean +20% food.
>
> It allows civilizations near rivers and oceans to develop a completely new food source and settlement strategy.

---

# Roguelite Era Progression

A civilization is temporary.

The player decides when the current civilization has reached a suitable point to end its era.

Ending an era resets the civilization's temporary progress, but permanent progression is retained.

### Temporary

- Population
- Current resource stockpiles
- Current buildings
- Current workforce
- Temporary military strength
- Current political relationships

### Permanent

- Research discoveries
- Technology unlocks
- Legacy bonuses
- Certain monuments and structures
- World changes
- Historical records

This creates a classic idle/roguelite progression loop without forcing every civilization into a fixed 20-minute timer.

---

# Civilization Legacy

Every civilization should have the opportunity to leave something behind.

Examples:

### Ancient Road

Future civilizations can use it to move through the region more efficiently.

### Great Granary

Provides a food-production or storage bonus to future civilizations.

### Ancient Library

Provides a research bonus.

### Monument

Records the existence and achievements of the civilization that built it.

### Ancient City

A future civilization may settle on or near the ruins and gain access to inherited infrastructure.

Not every legacy needs to be economically optimal. Some structures exist simply because the civilization built them and they became part of the world's history.

---

# The Persistent World

The procedural world is generated at the beginning of a game and persists throughout the entire playthrough.

The player does **not** receive a completely new map after each reset.

The same:

- Mountains
- Rivers
- Lakes
- Coastlines
- Forests
- Deserts
- Fertile regions
- Resource deposits
- Strategic locations

remain in place.

Civilizations gradually alter this landscape.

```text
Wilderness
    ↓
Settlement
    ↓
Village
    ↓
Town
    ↓
City
    ↓
Abandoned Ruins
    ↓
New Civilization
    ↓
Rebuilt City
```

The map becomes a record of everything that happened there.

---

# AI Civilizations

The player is not alone.

Other civilizations are generated and placed around the world.

AI civilizations:

- Start in different locations.
- Have their own civilization traits.
- Gather resources automatically.
- Build and expand automatically.
- Research technologies independently.
- Grow their populations.
- Develop at different rates.
- Establish trade routes.
- Form diplomatic relationships.
- Make alliances.
- Compete for territory and resources.
- Declare and fight wars.
- Can rise, decline and potentially disappear.

AI civilizations should not simply be decorative factions. They should be running through the same broad simulation rules as the player's civilization.

Their development should create a world that continues changing even when the player is focused elsewhere.

---

# Civilization Selection

At the beginning of an era, the player chooses from **three civilization options**.

Each civilization has its own strengths, weaknesses and unique bonuses.

Example archetypes:

### The Agrarians

- Strong food production.
- Faster population growth.
- Stronger farming technologies.

### The Traders

- Improved trade.
- Larger markets.
- Better diplomatic relationships.

### The Builders

- Faster construction.
- Cheaper buildings.
- Stronger infrastructure.

These are examples only. The final civilization roster will be designed around meaningful differences in playstyle rather than simple percentage upgrades.

AI civilizations receive randomly selected civilization traits so that each world develops differently.

---

# Diplomacy

Civilizations can interact with one another through a diplomatic system.

Planned relationships include:

- Neutral
- Friendly
- Trade Partner
- Allied
- Rival
- Hostile
- At War

Diplomatic relationships can change based on factors such as:

- Territory
- Trade
- Shared borders
- Military strength
- Resources
- Previous conflicts
- Civilization traits
- Player actions

The goal is for diplomacy to emerge from the world rather than being a list of scripted missions.

---

# Trade

Civilizations can exchange resources and goods.

Trade should create meaningful relationships and economic opportunities.

For example:

```text
Civilization A
Rich in food
Poor in stone
	   ↓
	 TRADE
	   ↓
Civilization B
Rich in stone
Poor in food
```

A civilization with access to the coast may develop around fishing and trade, while a civilization surrounded by mountains may develop mining and metallurgy.

Geography should therefore influence economic development.

---

# War

Conflict is a natural part of the world simulation.

Civilizations may fight over:

- Territory
- Resources
- Strategic locations
- Trade routes
- Diplomatic disputes
- Historical rivalries

The player should not need to manually command every soldier.

War is primarily a high-level simulation between civilizations, with the player's influence coming from development choices such as population, military infrastructure, technology and strategic expansion.

Possible outcomes include:

- Territory changing hands.
- Cities being damaged or destroyed.
- Populations declining.
- Resources becoming scarce.
- New borders being established.
- Long-term rivalries developing.
- Ancient battlefields becoming part of the persistent world.

---

# Emergent History

One of the main goals of the project is for every world to develop its own history.

A world might produce a history such as:

```text
Era 1
The River People establish the first settlement.

Era 2
The first farms are developed.

Era 3
The Stone Kingdom builds a road network.

Era 4
The River People and Stone Kingdom begin trading.

Era 5
A border dispute causes war.

Era 6
The Stone Kingdom captures an ancient city.

Era 7
The empire collapses.

Era 8
A new civilization settles among the ruins.
```

The player should eventually be able to look across the map and recognise that these events actually happened there.

---

# Civilization Records

Each completed civilization should produce a historical record.

Example:

> ## The Kingdom of Brendonia
>
> **Era:** 12  
> **Peak Population:** 8,421  
> **Territory:** 37 regions  
> **Technologies Discovered:** 14  
> **Monuments Built:** 3  
> **Wars:** 2  
> **Trade Agreements:** 6
>
> **Greatest Achievement:** The Great Library
>
> **Legacy:** +10% research speed for future civilizations beginning near the capital.

Historical records should make the player's persistent world feel like a collection of stories rather than a sequence of resets.

---

# Procedural World Generation

The world should be generated from data-driven rules rather than hand-authored maps.

The generator should determine things such as:

- World size
- Terrain
- Rivers and lakes
- Climate
- Resource distribution
- Fertile regions
- Mountain ranges
- Coastlines
- Strategic locations
- Starting locations
- AI civilization locations

The important rule is:

> **Generate the world once. Simulate it for the rest of the game.**

---

# Simulation Architecture

The project should separate data, simulation and presentation.

```text
Data
  ↓
World Generation
  ↓
World State
  ↓
Simulation Systems
  ↓
Civilization AI
  ↓
World Changes
  ↓
Scenes / UI
```

### Data

Defines what exists:

```text
data/
├── civilizations/
├── technologies/
├── buildings/
├── resources/
├── terrain/
├── traits/
├── diplomacy/
└── events/
```

### Generators

Create the initial world:

```text
scripts/
├── world/
├── terrain/
├── resources/
└── civilizations/
```

### Simulation

Handles changing world state:

```text
scripts/simulation/
├── population/
├── economy/
├── construction/
├── research/
├── diplomacy/
├── warfare/
└── world/
```

### Scenes

Display and interact with the simulated world.

The simulation should not depend on visual scenes wherever possible. A civilization should be able to continue simulating even when the player is zoomed far away or viewing another part of the map.

---

# Architecture Rules

- Data resources describe the game world.
- Generators create initial world state.
- Simulation systems modify world state.
- Civilization AI makes decisions using simulation data.
- Scenes display the world.
- UI communicates player choices to simulation systems.
- The world state should be saveable independently from scene state.
- AI civilizations should use the same core systems as the player wherever practical.
- Avoid giant manager scripts when a smaller domain system is sufficient.
- Systems should be testable independently.
- Keep the simulation deterministic where practical so bugs and historical events can be reproduced.

---

# Scope Philosophy

The previous concept for this project grew toward a large space RPG. This project deliberately takes a different approach.

The goal is not to simulate every aspect of human civilisation.

The goal is to make a **small, understandable simulation that produces interesting history**.

The first playable version should prove the following:

1. A civilization can gather resources automatically.
2. The player can choose buildings.
3. Buildings affect civilization development.
4. Population grows automatically.
5. Research unlocks new capabilities.
6. The player can end an era.
7. Permanent progression survives the reset.
8. The same world remains.
9. At least one AI civilization develops independently.
10. The player can observe meaningful interaction between civilizations.

If those ten things are fun, the project has a foundation worth expanding.

---

# Development Roadmap

## Milestone 0 - Project Foundation

**Status: COMPLETE**

- [x] Godot project configuration
- [x] Repository structure
- [x] Civilization-focused scene structure
- [x] Core world state
- [x] Save/load foundation

### Foundation implemented

The project now has a minimal runnable civilization-focused foundation:

- `WorldState` is a persistent autoload containing the world seed, era, simulation time, civilizations, world data and permanent legacy data.
- `SaveManager` is a persistent autoload providing JSON save/load to `user://civilization_save.json`.
- The main game scene loads an existing world or creates and saves a new one automatically.
- Civilization, world and main scene boundaries are established under `scenes/`.
- The project has been renamed from the original space-game prototype to **Unnamed Civilization Game**.
- The world state is intentionally independent from visual scenes so simulation data can later continue running while the player changes views.

Milestone 0 is deliberately small. It establishes the foundation needed for the procedural world, autonomous civilizations and persistent eras without prematurely implementing the simulation itself.

## Milestone 1 - Persistent Procedural World

**Status: IN PROGRESS**

- [x] Generate a persistent world map
- [ ] Generate terrain
- [ ] Generate resources
- [ ] Generate starting locations
- [ ] Save generated world seed
- [ ] Load the same world after restart

### Persistent world map implemented

The first Milestone 1 slice now generates a deterministic 64×64 world map from a world seed and stores the generated terrain data in WorldState. The map is rendered directly from world state, and the generated data is included in the existing JSON save system.

This deliberately stops before resources, civilization starting locations and the broader terrain/resource systems are implemented. Those remain separate Milestone 1 tasks.

## Milestone 2 - First Civilization

- [ ] Spawn player civilization
- [ ] Spawn initial population
- [ ] Automatic food gathering
- [ ] Automatic wood gathering
- [ ] Automatic population growth
- [ ] Fire Pit
- [ ] House
- [ ] Basic construction system
- [ ] Basic civilization simulation

## Milestone 3 - Idle Development

- [ ] Resource production rates
- [ ] Storage
- [ ] Building upgrades
- [ ] Population modifiers
- [ ] Additional resource types
- [ ] Civilization statistics

## Milestone 4 - Research

- [ ] Research Points
- [ ] Technology tree
- [ ] Technology unlocks
- [ ] Agriculture
- [ ] Fishing
- [ ] Stoneworking
- [ ] First permanent legacy unlocks

## Milestone 5 - Era Reset

- [ ] End-era system
- [ ] Permanent research progression
- [ ] Civilization selection
- [ ] Three initial civilization archetypes
- [ ] New civilization starts on the same world
- [ ] Historical records

## Milestone 6 - AI Civilizations

- [ ] AI civilization spawning
- [ ] Autonomous resource gathering
- [ ] Autonomous construction
- [ ] Autonomous research
- [ ] AI population growth
- [ ] AI expansion
- [ ] AI civilization traits

## Milestone 7 - Diplomacy and Trade

- [ ] Civilization relationships
- [ ] Trade agreements
- [ ] Resource exchange
- [ ] Alliances
- [ ] Diplomatic state changes

## Milestone 8 - Warfare

- [ ] Military development
- [ ] Territory control
- [ ] Wars
- [ ] Battles
- [ ] City damage
- [ ] Territory changes
- [ ] War history

## Milestone 9 - Persistent History

- [ ] Ancient ruins
- [ ] Persistent monuments
- [ ] Persistent roads
- [ ] Ancient cities
- [ ] Historical events
- [ ] Civilization history screen
- [ ] World history timeline

## Milestone 10 - Polish and Expansion

- [ ] More civilizations
- [ ] More technologies
- [ ] More buildings
- [ ] More terrain types
- [ ] More diplomatic behaviours
- [ ] Events
- [ ] Better visual feedback
- [ ] Audio
- [ ] UI polish
- [ ] Balance and progression tuning

---

# Long-Term Vision

The ideal end result is a game where the player can leave the simulation running, return later and discover that the world has changed.

A civilization that was once a tiny settlement may have become an empire.

A trading partner may have become a rival.

A mountain pass that was once empty may now contain a city.

A monument built dozens of eras ago may still stand.

And somewhere beneath the new civilization's foundations may be the ruins of a city the player themselves created many resets ago.

The ultimate progression is therefore not simply:

> **Make the numbers bigger.**

It is:

> **Make the world older, stranger and more interesting.**

---

# Current Status

**Early concept / active development.**

The repository is being rebuilt around the persistent civilization simulation described above. Features listed as planned are design targets rather than promises of the current prototype.
