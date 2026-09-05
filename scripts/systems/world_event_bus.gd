## Lightweight global signal bus for world-simulation events (autoload
## "WorldEvents"; docs/ARCHITECTURE.md "World Event Bus").
##
## Lets independent systems react to what's happening in the world without
## coupling to whichever system caused it. Right now only Hero emits these;
## citizens already react via the existing danger API (Citizen.react_to_danger),
## and later phases (police, news) can subscribe here too without ever
## knowing Hero exists.
##
## This is NOT the Event Director (docs/ROADMAP.md Phase 8) — that's a later
## pacing/orchestration system. This bus has no opinion about when things
## should happen, it only relays that they did.
extends Node

signal hero_activity_started(hero: Node3D)
signal vehicle_stolen(vehicle: Node3D, position: Vector3)
signal dangerous_driving_started(position: Vector3)
signal collision_occurred(position: Vector3)
signal danger_created(position: Vector3, radius: float)

## Phase 7 (NPC Survival) additions — connecting Hero/police chaos to the
## player's and citizens' ordinary lives.
signal vehicle_collision(position: Vector3)
signal player_injured(position: Vector3)
signal civilian_injured(position: Vector3)
signal player_died(position: Vector3, cause: String)
