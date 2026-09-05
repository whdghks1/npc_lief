# NPC LIFE — Roadmap

## Phase 0 — Project Foundation

Goal:

The project launches reliably.

Tasks:

- Create Godot project
- Establish folder structure
- Create test scene
- Configure input mappings
- Add debug overlay
- Document run instructions

Exit criteria:

Game launches into a basic 3D scene.

---

# Phase 1 — The Citizen

Goal:

Walking around feels functional.

Implement:

- third-person character
- camera
- movement
- interaction system
- health
- basic UI

Exit criteria:

Player can walk around and interact with objects.

---

# Phase 2 — Tiny City

Goal:

Create the smallest possible believable city.

Implement:

- 4x4-ish city blocks
- roads
- sidewalks
- apartment
- convenience store
- hospital
- police station
- simple traffic

Use placeholder/low-poly assets.

Exit criteria:

Player can walk from home to work.

---

# Phase 3 — A Normal Day

Goal:

NPC LIFE works without chaos.

Implement:

- clock
- day cycle
- job
- salary
- hunger
- food
- sleep
- basic economy

Exit criteria:

Player can:

wake up → travel to work → work → eat → return home → sleep.

This must be playable before implementing major chaos.

---

# Phase 4 — Living City

Implement:

- pedestrian NPCs
- basic schedules
- traffic
- citizen reactions
- fleeing behavior

Exit criteria:

The city feels active without the Hero.

---

# Phase 5 — The Hero

Implement one Hero AI.

Initial loop:

wander

↓

steal vehicle

↓

drive recklessly

↓

commit crime

↓

trigger police

↓

escape

↓

hide

Exit criteria:

Hero can create incidents without involving the player.

---

# Phase 6 — Police

Implement:

- police spawning/patrol
- crime response
- vehicle pursuit
- searching
- losing target

Exit criteria:

Hero and police can generate an unscripted chase through the city.

---

# Phase 7 — NPC Survival

Connect chaos to ordinary life.

Implement:

- collisions damaging civilians
- road closures
- player fleeing
- hospital
- death
- life report

Exit criteria:

A normal working day can unexpectedly become a survival situation.

---

# Phase 8 — Event Director

Implement pacing.

Goals:

- prevent nonstop chaos
- generate quiet periods
- vary event intensity
- allow off-screen incidents

Add news notifications.

Exit criteria:

Several playthroughs produce meaningfully different stories.

---

# Phase 9 — Vertical Slice

Focus on:

- visual identity
- sound
- UI
- animations
- balancing
- performance
- bugs

Do NOT expand the map yet.

Exit criteria:

A stranger can play for 30 minutes and understand why NPC LIFE is fun.

---

# Decision Gate

After Vertical Slice:

Ask:

1. Is being an NPC actually fun?
2. Do players naturally tell stories about what happened?
3. Does the Hero feel independent?
4. Are quiet periods enjoyable?
5. Do players want another life after dying?

If YES:

Proceed toward Steam prototype/demo.

If NO:

Change the core loop before adding content.

---

# Future — Only After Validation

Potential systems:

- multiple jobs
- housing
- insurance
- relationships
- public transportation
- different Hero personalities
- multiple Heroes
- weather
- city districts
- property damage
- persistent world
- Steam achievements
- Steam Deck support

These are intentionally NOT part of the initial prototype.