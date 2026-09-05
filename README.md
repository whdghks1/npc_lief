# NPC LIFE

A 3D life-survival sim where you are *not* the hero — see [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and [docs/ROADMAP.md](docs/ROADMAP.md) for the
full design, architecture, and phase plan.

## Status

**Phase 2 — Tiny City** in progress (see [docs/ROADMAP.md](docs/ROADMAP.md)).

The game boots into a small procedurally-laid-out city: a 4x4 grid of blocks connected by
roads, with an apartment (home), convenience store (work), hospital, and police station —
plus filler buildings for skyline variety, and a couple of vehicles looping the perimeter
road as placeholder traffic. The player spawns at home; the convenience store sits at the
far corner of the city, so reaching it is a real walk across town.

`scenes/world/main.tscn` still exists as a small isolated sandbox (from Phase 0/1) for
testing player/interaction features without the whole city loaded.

## Requirements

- [Godot Engine 4.7.x](https://godotengine.org/download) (standard build, GDScript — no .NET/Mono
  build required).

## Running the project

1. Open Godot Engine.
2. Click **Import**, select this folder's `project.godot`, and open the project.
3. Press **F5** (or the Play button) to run.

Or from the command line:

```sh
godot --path .
```

You should see the player character standing right outside a labeled building marked
**Home**. Walking away reveals a grid of streets and other buildings, including
**Convenience Store**, **Hospital**, and **Police Station** signs floating above their
buildings, and a couple of cars looping around the outer road.

## Controls

| Action                  | Key         |
|--------------------------|-------------|
| Move                       | W / A / S / D |
| Look around                | Mouse       |
| Jump                       | Space       |
| Interact                  | E           |
| Release/recapture mouse    | Escape      |
| Toggle debug overlay       | F3          |

Your HP (100/100, static for now — nothing damages the player yet) shows at the
bottom-left. Interaction (E) has no target in the city yet — buildings aren't functional
until Phase 3 (job/economy).

## Verifying the project headlessly

Godot can import assets and run a project without opening a window, which is useful for CI
or a quick sanity check after changes:

```sh
godot --headless --path . --import          # (re)import assets, prints any import errors
godot --headless --path . --quit-after 20   # boot the main scene for 20 frames, then quit
```

Both commands should complete with no `ERROR`/`SCRIPT ERROR` output, and the second should
print something like `NPC LIFE — city generated (4x4 blocks), player spawned at home: ...`.
This catches script/scene errors but can't confirm movement, camera, or navigation actually
feel right — open the project in the editor for that.

## Project structure

Follows [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md):

```
scenes/       world, player, citizens, hero, police, vehicles, buildings, ui
scripts/      player, ai/{citizen,hero,police}, simulation/{time,traffic,city},
              systems/{event_director,economy,jobs,news}, core, ui
data/         jobs, events, vehicles, citizens (data-driven resources)
assets/       art/audio assets
docs/         design/architecture/roadmap docs
```

Most of these directories are currently placeholders (`.gitkeep`) reserved for systems
introduced in later roadmap phases — see [docs/ROADMAP.md](docs/ROADMAP.md) before adding to them.
