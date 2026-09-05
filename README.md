# NPC LIFE

A 3D life-survival sim where you are *not* the hero — see [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and [docs/ROADMAP.md](docs/ROADMAP.md) for the
full design, architecture, and phase plan.

## Status

**Phase 0 — Project Foundation**: done.
**Phase 1 — The Citizen**: done.
**Phase 2 — Tiny City**: done.
**Phase 3 — A Normal Day**: done.
**Phase 4 — Living City**: done (see [docs/ROADMAP.md](docs/ROADMAP.md)).

The player can play a full ordinary day (wake → work → eat → sleep, see below) inside a
city that now feels inhabited on its own: 16 placeholder citizens walk between home, work,
and the store on simple daily schedules, using Godot's navigation system to actually route
around buildings, and traffic keeps looping regardless of what the player does. There is
still no chaos, Hero, or police — by design, per [docs/ROADMAP.md](docs/ROADMAP.md)'s
phase scope.

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

1. Wake up at Home (every day, including Day 1, starts at 07:00).
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

## The living city

Independent of anything the player does, the city keeps going:

- **16 citizens** (plain gray capsules, randomly tinted) each follow one of two schedule
  archetypes: a "worker" (leaves home for the store at 07:30, takes a break at noon, heads
  home at 17:00) or a "shopper" (visits the store around 09:00, home by 12:30). They path
  there using a baked NavigationRegion3D, so they walk around buildings rather than through
  them.
- A handful of **cars** loop continuously around the outer road.
- None of this needs the player nearby or even present — leave the city running (or use the
  time debug hotkeys below) and citizens keep moving through their day regardless.

Citizens also expose `react_to_danger()`, `flee_from()`, and `resume_schedule()` — a Flee
state and reaction hooks for the Hero/chaos systems Phase 5 adds, but nothing calls them
yet.

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
| 8   | Toggle per-citizen state/destination readout |
| 9   | Toggle engine navigation debug draw (best-effort; not on every build) |

The overlay also always shows the current citizen count.

## Known limitations (expected at this phase)

- Only one job exists (Convenience Store Worker); no job selection.
- Only two food items; no inventory system.
- Sleeping always fully restores hunger regardless of how you spent the day.
- No chaos, Hero AI, police, or crime — intentionally out of scope until later phases.
- Hospital and Police Station are non-functional placeholder buildings (labels only).
- Citizens don't own individual homes — they use the generic filler buildings' fronts as
  stand-in residences, and every "worker" shares the same one workplace (there's only one).
- Citizens don't avoid each other (no crowd avoidance), so they can overlap one another —
  deliberate, docs/ROADMAP.md Phase 4 explicitly excludes crowd simulation. They *do*
  physically block the player (and vice versa), just not each other.
- The debug time-speed-up hotkey ([2]) also speeds up citizen/vehicle movement
  proportionally (`TimeSystem.speed_multiplier()`), so fast-forwarding looks like an actual
  time-lapse rather than just the clock spinning while everyone keeps walking normally. The
  player's own movement speed is never affected by this.
- If a citizen's baked path can't quite resolve the final few meters to a destination (rare,
  navmesh-precision dependent), it falls back to walking there in a direct line after a
  brief pause rather than getting stuck — see the comment on `STUCK_CHECK_INTERVAL` in
  `scripts/ai/citizen/citizen.gd`.

## Verifying the project headlessly

Godot can import assets and run a project without opening a window, which is useful for CI
or a quick sanity check after changes:

```sh
godot --headless --path . --import          # (re)import assets, prints any import errors
godot --headless --path . --quit-after 20   # boot the main scene for 20 frames, then quit
```

Both commands should complete with no `ERROR`/`SCRIPT ERROR` output, and the second should
print something like `NPC LIFE — city generated (4x4 blocks), 16 citizens, player spawned
at home: ...`. This catches script/scene errors but can't confirm movement, camera, or the
daily loop actually feel right — open the project in the editor for that. To actually watch
the city live for a while, use debug hotkey **2** to speed up time and stand still for a
few in-game hours — citizens should keep moving through their schedule the whole time.

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

Notable Phase 4 additions:

- `scripts/ai/citizen/citizen.gd` — the citizen state machine (Idle, WalkToDestination,
  Work, Eat, ReturnHome, Flee) and reaction API.
- `scripts/ai/citizen/citizen_schedule.gd` — schedule archetype data;
  `data/citizens/schedule_worker.tres` and `schedule_shopper.tres` are the two in use.
- `CityBuilder` now bakes a `NavigationRegion3D` from the city's own collision geometry and
  spawns citizens onto it (see the class doc in `city_builder.gd` for why sidewalks ended up
  flush with the road instead of raised, and why the navmesh agent radius is smaller than
  citizens' actual collision radius — both were real bugs found while getting pathing to
  work reliably here).

`CityBuilder` only constructs the city and attaches/spawns these components at the right
buildings — it does not contain job/economy/hunger/citizen *logic* itself (see the
architecture note at the top of `scripts/simulation/city/city_builder.gd`).

Most remaining directories are still placeholders (`.gitkeep`) reserved for systems
introduced in later roadmap phases — see [docs/ROADMAP.md](docs/ROADMAP.md) before adding to them.
