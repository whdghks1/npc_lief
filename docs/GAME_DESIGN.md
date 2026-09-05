# NPC LIFE — Game Design

## High Concept

NPC LIFE is a 3D life-survival simulation where the player is not the hero.

The player is an ordinary citizen living in an open-world city where unpredictable "main-character-like" individuals create chaos.

The player's goal is simple:

**Live an ordinary life and survive.**

Go to work.
Earn money.
Eat.
Pay rent.
Buy a car.
Go home.

Meanwhile, somewhere in the city:

- a robbery may occur
- police may start a pursuit
- someone may steal a vehicle
- explosions may occur
- roads may become blocked
- a dangerous individual may enter the player's neighborhood

The player is not expected to fight these threats.

The player is expected to survive them.

---

## Design Pillars

### 1. You Are Not The Hero

The player should feel insignificant compared with the chaos occurring around them.

Combat must never become the primary gameplay loop.

Avoid turning NPC LIFE into a conventional action game.

### 2. Ordinary Life Creates Stakes

The player should care about:

- getting to work
- earning money
- keeping their job
- paying rent
- protecting their possessions
- getting home safely

Chaos matters because it interrupts ordinary life.

### 3. Chaos Exists Without The Player

Events must not always spawn around the player.

The city should feel like it exists independently.

A major event may happen:

- directly beside the player
- several blocks away
- across the city
- completely outside the player's experience

The player may only hear about an event through news or NPC conversations.

### 4. Every Life Creates A Story

The game should naturally generate stories.

Example:

Day 8.

The player wakes up late.

They take a taxi instead of the bus.

A police pursuit blocks the main road.

The taxi takes another route.

The player arrives late and loses part of their salary.

On the way home, they discover their parked vehicle was destroyed during the pursuit.

None of this should require a scripted mission.

---

# Core Gameplay Loop

Wake up

↓

Prepare for the day

↓

Travel to work

↓

Work / earn money

↓

Handle daily needs

↓

React to city events

↓

Return home

↓

Sleep

↓

Next day

The player attempts to improve their life while surviving unpredictable city events.

---

# Player Systems

Initial prototype player stats:

- Health
- Money
- Hunger
- Energy
- Employment
- Home
- Current schedule

Possible later systems:

- Stress
- Relationships
- Insurance
- Reputation
- Happiness
- Injuries
- Property ownership

Do NOT implement all of these in the prototype.

---

# Jobs

Prototype:

- Convenience Store Worker

Later possibilities:

- Office Worker
- Taxi Driver
- Delivery Driver
- Construction Worker
- Police Dispatcher
- Mechanic
- Unemployed

Jobs exist primarily to give the player routines and reasons to travel through the city.

---

# Hero System

The "Hero" is an AI-controlled character that behaves like a player character from an open-world action game.

The Hero exists independently of the player.

Possible Hero behaviors:

- wander
- steal vehicle
- drive recklessly
- commit robbery
- attract police attention
- flee from police
- crash
- abandon vehicle
- cause collateral damage
- disappear

The Hero should NOT constantly target the player.

The player is irrelevant to the Hero.

This is essential to the game's identity.

---

# Event Director

The Event Director controls the overall intensity of the city.

Example intensity levels:

0 — Peaceful
1 — Minor incident
2 — Police activity
3 — Major pursuit
4 — City-scale chaos

The director should avoid constant chaos.

Quiet periods are necessary.

Without ordinary life, extraordinary events stop feeling extraordinary.

---

# Death

Death ends the current citizen's life.

Display a Life Report.

Example:

NPC LIFE

Name: Alex
Occupation: Convenience Store Worker

Days survived: 17

Money earned: $8,420
Distance travelled: 93 km
Times late to work: 4
Major incidents survived: 7

Cause of death:
Struck by stolen vehicle.

[ Start New Life ]

Future versions may allow inheritance or persistent city history.

---

# Art Direction

Stylized 3D.

Prefer:

- low-poly environments
- readable silhouettes
- colorful city environments
- relatively simple materials
- humorous visual contrast

Do NOT pursue photorealism.

The contrast between a friendly-looking city and absurd background chaos is part of the game's tone.

---

# Prototype Scope

The first playable prototype contains:

- one small city district
- approximately 4x4 city blocks
- player apartment
- convenience store workplace
- restaurant
- hospital
- police station
- roads
- pedestrian NPCs
- basic vehicles
- day/night clock
- one job
- one Hero AI
- police response
- basic death system

The prototype succeeds if:

**The player can complete an ordinary day while unpredictable events happen around them, and the experience produces funny or memorable stories.**