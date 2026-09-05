# NPC LIFE — Agent Instructions

You are developing NPC LIFE, a Godot 4.x 3D indie game.

Before making architectural or gameplay changes, read:

- docs/GAME_DESIGN.md
- docs/ARCHITECTURE.md
- docs/ROADMAP.md

These documents define the project's intended direction.

## Core Rule

NPC LIFE is NOT an action game.

The player is an ordinary NPC attempting to live a normal life while action-game-like chaos occurs independently around them.

Never redesign the player into the hero.

## Development Philosophy

Prioritize:

1. playable functionality
2. clear architecture
3. iteration speed
4. emergent gameplay
5. performance
6. polish

Avoid premature complexity.

Use placeholders when assets are unavailable.

Do not block implementation because final art does not exist.

## Scope Control

Work on the current roadmap phase only unless a dependency requires otherwise.

Do not implement future roadmap systems merely because they may eventually be useful.

Do not expand the city until the core gameplay loop has been validated.

## Architecture

Keep major systems decoupled.

Prefer signals/events for communication between simulation systems.

Avoid giant manager scripts.

Keep data configurable where practical.

## AI

Start with simple state machines.

Do not introduce behavior trees, GOAP, machine learning, LLM-controlled NPCs or other complex AI systems unless explicitly requested.

The illusion of intelligent behavior is more important than technical sophistication.

## Hero Rule

The Hero:

- exists independently
- does not revolve around the player
- does not constantly attack the player
- may cause events the player never witnesses
- should behave like someone playing an open-world action game

## Development Tools

Build useful debug tools whenever implementing simulation systems.

Important debug abilities include:

- change time
- pause simulation
- change simulation speed
- spawn Hero
- force Hero state
- trigger crime
- spawn police
- change chaos level
- teleport player
- reset current life

## Code Quality

Use typed GDScript where practical.

Keep scripts focused.

Document non-obvious architecture decisions.

Remove dead code.

Do not leave unexplained temporary hacks.

## Validation

After completing a task:

1. ensure the project starts
2. check for Godot errors
3. verify existing behavior still works
4. manually verify the new feature
5. update documentation when architecture changed

## Current Objective

Read docs/ROADMAP.md.

Determine the earliest incomplete phase.

Implement only what is necessary to complete that phase.

If the repository is empty, begin with Phase 0.

Do not attempt to build the entire game in one pass.