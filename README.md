# NPC LIFE

A 3D life-survival sim where you are *not* the hero — see [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and [docs/ROADMAP.md](docs/ROADMAP.md) for the
full design, architecture, and phase plan.

## Status

**Phase 0 — Project Foundation** (see [docs/ROADMAP.md](docs/ROADMAP.md)).

The project boots into a placeholder 3D scene (ground plane + a box) with a debug overlay
and a base input map. No gameplay yet — that starts in Phase 1.

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

You should see a small outdoor scene (green ground plane, an orange placeholder box, a
directional light) and a debug overlay in the top-left corner showing the current FPS.

## Controls

Input mappings configured so far (used starting Phase 1 — nothing consumes movement yet):

| Action                  | Key    |
|--------------------------|--------|
| Move forward              | W      |
| Move back                 | S      |
| Move left                 | A      |
| Move right                | D      |
| Jump                       | Space  |
| Interact                  | E      |
| Pause                      | Escape |
| Toggle debug overlay       | F3     |

## Verifying the project headlessly

Godot can import assets and run a project without opening a window, which is useful for CI
or a quick sanity check after changes:

```sh
godot --headless --path . --import          # (re)import assets, prints any import errors
godot --headless --path . --quit-after 20   # boot the main scene for 20 frames, then quit
```

Both commands should complete with no `ERROR`/`SCRIPT ERROR` output, and the second should
print `NPC LIFE — Phase 0 test scene loaded.`.

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
