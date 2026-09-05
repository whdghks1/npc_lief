# NPC LIFE

A 3D life-survival sim where you are *not* the hero — see [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and [docs/ROADMAP.md](docs/ROADMAP.md) for the
full design, architecture, and phase plan.

## Status

**Phase 0 — Project Foundation**: done.
**Phase 1 — The Citizen**: done.
**Phase 2 — Tiny City**: done.
**Phase 3 — A Normal Day**: done (see [docs/ROADMAP.md](docs/ROADMAP.md)).

The game boots into a small procedurally-laid-out city (4x4 blocks: an apartment/home,
convenience store, hospital, police station, filler buildings, and a couple of looping
traffic vehicles). The player can now play a full ordinary day: wake up at home, walk to
the convenience store, work a shift for a salary, buy and eat food, walk home, and sleep to
advance to the next day. There is still no chaos, Hero, or police — by design, per
[docs/ROADMAP.md](docs/ROADMAP.md) Phase 3's scope.

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

You start right outside **Home**. The HUD shows your day/time (top-right), a daily
objective hint (top-center), and HP/Hunger/Money (bottom-left).

## The daily loop

1. Wake up at Home (Day starts at 08:00).
2. Walk to the **Convenience Store** (far corner of the city) — the shift starts at 09:00.
3. Interact with the store (**E**) to start your shift. Time skips forward to your shift's
   end (17:00) and your salary is paid — arrive too late and you're docked a late penalty
   instead.
4. Hunger drains slowly over time. Interact with the **Snack** ($3, +15 hunger) or **Meal**
   ($8, +40 hunger) stands next to the store to eat.
5. Walk back Home and interact with it (**E**) to sleep — this restores hunger fully and
   advances to the next morning.
6. Repeat. Working twice in the same day does nothing (you already worked today).

The top-center objective hint tracks this loop automatically ("Go to work — shift starts
at 09:00" → "Buy something to eat" → "Return home and sleep" → ...).

## Controls

| Action                  | Key         |
|--------------------------|-------------|
| Move                       | W / A / S / D |
| Look around                | Mouse       |
| Jump                       | Space       |
| Interact                  | E           |
| Release/recapture mouse    | Escape      |
| Toggle debug overlay       | F3          |

### Debug hotkeys (only active while the debug overlay is visible)

| Key | Effect |
|-----|--------|
| 1   | Advance time by 1 hour |
| 2   | Toggle fast time (x40) / normal time (x2) |
| 3 / 4 | Add / subtract $20 |
| 5 / 6 | Hunger -20 / restore to full |
| 7   | Skip to next day (same as sleeping) |

## Known limitations (expected at this phase)

- Only one job exists (Convenience Store Worker); no job selection.
- Only two food items; no inventory system.
- Sleeping always fully restores hunger regardless of how you spent the day.
- No chaos, Hero AI, police, or crime — intentionally out of scope until later phases.
- Hospital and Police Station are non-functional placeholder buildings (labels only).

## Verifying the project headlessly

Godot can import assets and run a project without opening a window, which is useful for CI
or a quick sanity check after changes:

```sh
godot --headless --path . --import          # (re)import assets, prints any import errors
godot --headless --path . --quit-after 20   # boot the main scene for 20 frames, then quit
```

Both commands should complete with no `ERROR`/`SCRIPT ERROR` output, and the second should
print something like `NPC LIFE — city generated (4x4 blocks), player spawned at home: ...`.
This catches script/scene errors but can't confirm movement, camera, or the daily loop
actually feel right — open the project in the editor for that.

## Project structure

Follows [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md):

```
scenes/       world, player, citizens, hero, police, vehicles, buildings, ui
scripts/      player, ai/{citizen,hero,police}, simulation/{time,traffic,city},
              systems/{event_director,economy,jobs,objectives,news}, core, ui
data/         jobs, events, vehicles, citizens (data-driven resources)
assets/       art/audio assets
docs/         design/architecture/roadmap docs
```

Notable Phase 3 additions:

- `scripts/simulation/time/time_system.gd` — global clock (autoload `TimeSystem`).
- `scripts/systems/jobs/` — `job_definition.gd` (data), `player_job.gd` (shift state),
  `workplace_trigger.gd` (placed by CityBuilder on the store).
- `scripts/systems/economy/wallet.gd`, `food_item_trigger.gd`.
- `scripts/player/hunger.gd`.
- `scripts/systems/objectives/objective_tracker.gd` — the HUD's daily hint text.
- `scripts/systems/time/sleep_trigger.gd` — placed by CityBuilder on the apartment.

`CityBuilder` only constructs the city and attaches these components to the right
buildings — it does not contain job/economy/hunger logic itself (see the architecture note
at the top of `scripts/simulation/city/city_builder.gd`).

Most remaining directories are still placeholders (`.gitkeep`) reserved for systems
introduced in later roadmap phases — see [docs/ROADMAP.md](docs/ROADMAP.md) before adding to them.
