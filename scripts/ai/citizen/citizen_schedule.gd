## Data for a reusable daily-routine archetype (docs/ARCHITECTURE.md "Data
## Driven Design" — NPC schedules should be data-driven, not hardcoded into
## the citizen controller). A handful of these archetypes are shared across
## many Citizen instances; see data/citizens/.
##
## Each entry is a Dictionary {"minute_of_day": int, "action": String}.
## Entries fire once per day, in order, when TimeSystem's clock reaches their
## minute_of_day. Actions match what scripts/ai/citizen/citizen.gd knows how
## to do: "go_work", "go_food", "go_home", "eat_here" (a stationary break —
## no travel, e.g. lunch at the workplace).
class_name CitizenSchedule
extends Resource

@export var entries: Array[Dictionary] = []
