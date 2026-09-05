# NPC LIFE

A 3D life-survival sim where you are *not* the hero — see [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and [docs/ROADMAP.md](docs/ROADMAP.md) for the
full design, architecture, and phase plan.

## Status

**Phase 1 — The Citizen** in progress (see [docs/ROADMAP.md](docs/ROADMAP.md)).

The project boots into a small placeholder scene with a third-person player character:
camera-relative movement, an orbiting/collision-aware camera, a generic interaction system
(with one demo interactable object), a health stat, and a basic HUD.

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

You should see a small outdoor scene: a blue capsule character standing on a green ground
plane, an orange placeholder box (solid obstacle), and a cyan sphere (a demo interactable
object) — plus a debug overlay in the top-left corner showing the current FPS.

## Controls

| Action                  | Key         |
|--------------------------|-------------|
| Move                       | W / A / S / D |
| Look around                | Mouse       |
| Jump                       | Space       |
| Interact                  | E           |
| Release/recapture mouse    | Escape      |
| Toggle debug overlay       | F3          |

Walk up to the cyan sphere — a prompt appears at the bottom of the screen ("[E] Look at the
object"); press **E** and it changes color and prints a message to the console. Your HP
(100/100, static for now — nothing damages the player yet) shows at the bottom-left.

## Verifying the project headlessly

Godot can import assets and run a project without opening a window, which is useful for CI
or a quick sanity check after changes:

```sh
godot --headless --path . --import          # (re)import assets, prints any import errors
godot --headless --path . --quit-after 20   # boot the main scene for 20 frames, then quit
```

Both commands should complete with no `ERROR`/`SCRIPT ERROR` output, and the second should
print `NPC LIFE — test scene loaded.`. This catches script/scene errors but can't confirm
movement, camera, or interaction actually feel right — open the project in the editor for that.

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
