# NPC LIFE

A 3D life-survival sim where you are *not* the hero — see [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and [docs/ROADMAP.md](docs/ROADMAP.md) for the
full design, architecture, and phase plan.

## Status

**Phase 0 — Project Foundation**: done.
**Phase 1 — The Citizen**: done.
**Phase 2 — Tiny City**: done.
**Phase 3 — A Normal Day**: done.
**Phase 4 — Living City**: done.
**Phase 5 — The Hero**: done (see [docs/ROADMAP.md](docs/ROADMAP.md)).

The player can play a full ordinary day (wake → work → eat → sleep, see below) inside a
city that feels inhabited on its own — citizens on daily schedules, looping traffic — and
now, occasionally, genuinely disruptive: an autonomous Hero wanders the city, steals a car,
drives recklessly, and causes an incident, entirely on its own timeline. There is still no
police response or event pacing — by design, per [docs/ROADMAP.md](docs/ROADMAP.md)'s
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

## The Hero

Somewhere in the city, an autonomous "Hero" (a dark red capsule) lives its own open-world-
action-game life, completely independent of the player:

1. **Wander** — walks the city on foot with no destination in particular, for 10-20s.
2. **Select/Approach/Steal a vehicle** — picks the nearest available car and walks to it.
   (The targeted car waits in place rather than continuing its loop — otherwise a
   pedestrian could never catch up to something several times its walking speed; this is
   the "vehicle stops or becomes available" simplification docs/ROADMAP.md calls for.)
   Once close enough, the Hero takes it — it disappears and the car starts driving
   recklessly.
3. **Drive** — the stolen car heads to random points around the city at high speed,
   ignoring the normal traffic loop, for 8-16s.
4. **Commit a crime** — a brief incident: `WorldEvents.danger_created` (and related
   signals) fire at the Hero's location, and any citizen within ~15m calls
   `react_to_danger()` on itself and flees. Citizens resume their normal schedule on their
   own a few seconds later — the Hero never has to tell them to stop being scared.
5. **Escape** — more reckless driving, away from the incident, for ~10s.
6. **Hide** — abandons the car where it stops (it just sits there, abandoned) and lays low
   on foot for ~6s.
7. **Cooldown** — wanders normally for ~15s (a guaranteed calm period) before being willing
   to steal another vehicle, then the loop repeats.

The Hero never queries the player's position — it picks a vehicle by proximity to *itself*,
not to the player, and can run its entire loop while the player is on the opposite side of
the city. You might see it from a distance, hear about it later, or never notice at all.

Citizens expose `react_to_danger()`, `flee_from()`, and `resume_schedule()` as a general
reaction API — the Hero is the first thing to call them, and later phases (police, other
danger sources) can reuse the same hooks without any new citizen code.

`WorldEvents` (autoload) is a small signal bus — `hero_activity_started`, `vehicle_stolen`,
`dangerous_driving_started`, `collision_occurred`, `danger_created` — so future systems
(police response, news) can react to what the Hero does without coupling to it directly.
This is not the Event Director (docs/ROADMAP.md Phase 8): it has no pacing logic, it only
relays that something happened.

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
| 0   | Force the Hero to immediately steal the nearest vehicle and commit a crime |
| H   | Teleport the player next to the Hero's current position |

The overlay always shows the current citizen count and a one-line Hero status (state,
whether it's driving, and which vehicle). Debug hotkeys never change simulation behavior
unless actually pressed — key **0** is for quickly verifying the crime/citizen-reaction
chain without waiting out the Hero's normal timing.

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
- If a citizen's (or the Hero's) baked path can't quite resolve the final few meters to a
  destination (rare, navmesh-precision dependent), it falls back to walking there in a
  direct line after a brief pause rather than getting stuck — see the comment on
  `STUCK_CHECK_INTERVAL` in `scripts/ai/citizen/citizen.gd`.
- Only one Hero exists, and there's no police response yet — a stolen car just gets
  abandoned and sits there permanently; nothing ever tows it or reacts further.
- Vehicle "theft" and driving are position-only (no enter/exit animation, no actual vehicle
  physics) — deliberately simple per docs/ROADMAP.md Phase 5's scope.
- The Hero's own state timers (wander/drive/escape/etc. durations) are real-time and do NOT
  speed up with the debug time-scale hotkey, unlike its walking/driving speed — only
  movement is tied to `TimeSystem.speed_multiplier()`.

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

Notable Phase 5 additions:

- `scripts/ai/hero/hero_ai.gd` — the Hero state machine (Wander, SelectVehicle,
  ApproachVehicle, StealVehicle, Drive, CommitCrime, Escape, Hide, Cooldown).
- `scripts/systems/world_event_bus.gd` — the `WorldEvents` signal bus.
- `scripts/simulation/traffic/simple_vehicle.gd` gained `driver`/`drive_to()`/
  `stop_driving()`/`freeze()` — a vehicle has no idea *who* is driving it or why, it just
  takes orders once it has a driver, so HeroAI (and later, anyone else) owns all the
  reckless-driving decisions.

`CityBuilder` only constructs the city and attaches/spawns these components at the right
buildings — it does not contain job/economy/hunger/citizen/Hero *logic* itself (see the
architecture note at the top of `scripts/simulation/city/city_builder.gd`).

Most remaining directories are still placeholders (`.gitkeep`) reserved for systems
introduced in later roadmap phases — see [docs/ROADMAP.md](docs/ROADMAP.md) before adding to them.
