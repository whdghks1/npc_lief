# NPC LIFE — Architecture

## Engine

Godot 4.x

Language:

GDScript

Target:

Desktop PC first.

Potential distribution:

Steam.

---

# Architecture Principles

Systems should communicate through events/signals where practical.

Avoid tightly coupling:

- Player
- Hero AI
- Police
- Event Director
- City simulation

The simulation must continue without requiring player involvement.

---

# Suggested Project Structure

res://

scenes/
    world/
    player/
    citizens/
    hero/
    police/
    vehicles/
    buildings/
    ui/

scripts/

    player/

    ai/
        citizen/
        hero/
        police/

    simulation/
        time/
        traffic/
        city/

    systems/
        event_director/
        economy/
        jobs/
        news/

data/
    jobs/
    events/
    vehicles/
    citizens/

assets/

docs/

---

# Core Systems

## GameManager

Responsible for:

- game state
- starting/ending lives
- save/load coordination

Must NOT contain gameplay logic belonging to other systems.

---

## TimeSystem

Maintains simulation time.

Responsibilities:

- time of day
- day counter
- time scaling
- schedule notifications

---

## PlayerController

Responsibilities:

- movement
- interaction
- player state

Do not put economy or job logic directly inside PlayerController.

---

## Citizen AI

Use a simple state-based architecture initially.

Possible states:

Idle
WalkToDestination
Work
Eat
Travel
Flee
ReturnHome

NPC schedules should be data-driven.

---

## Hero AI

Hero AI should use a state machine.

Initial states:

Wander
SelectVehicle
StealVehicle
Drive
CommitCrime
EscapePolice
Hide

Later versions may move toward utility AI or GOAP if necessary.

Do not implement a complex AI framework until the prototype proves it is necessary.

---

## Police AI

Initial states:

Patrol
Investigate
Pursue
Search
ReturnToPatrol

Police react to world events rather than directly querying the Hero whenever possible.

---

# World Event Bus

Important simulation events should be broadcast.

Examples:

crime_committed
vehicle_stolen
explosion_occurred
collision_occurred
police_alerted
hero_spotted
civilian_injured

Systems can subscribe to events.

Example:

Hero steals car

↓

vehicle_stolen event

↓

Police system receives event

↓

Police units respond

↓

Traffic reacts

↓

News system may report event

The player does not need to be involved.

---

# Event Director

The Event Director manages pacing.

It should consider:

- current chaos level
- time since previous incident
- current Hero state
- number of active police
- player location
- recent events

Important:

Player location may influence event visibility but should NOT guarantee events occur near the player.

---

# Data Driven Design

Jobs, events and character archetypes should be resources/data rather than hardcoded whenever reasonable.

Example Job:

name
work_location
start_time
end_time
salary
late_penalty

This allows future content to be added without rewriting core systems.

---

# Performance

Prototype target:

60 FPS on a normal desktop gaming PC.

Initial strategies:

- simple geometry
- low-poly assets
- limited active AI
- object pooling where useful
- distance-based AI update frequency

Do not prematurely build complex optimization systems.

Profile first.

---

# Save Data

Eventually save:

- current day
- money
- employment
- player inventory
- owned property
- statistics

Prototype save functionality can remain minimal.

---

# Testing Philosophy

Systems should be testable independently.

Create debug controls for:

- spawning Hero events
- changing time
- changing chaos level
- spawning vehicles
- spawning police
- killing/resetting player

Debug tooling is considered part of development, not optional polish.