## Listens to WorldEvents and assigns an available police unit to respond
## (autoload "PoliceDispatcher"). This is NOT the Event Director
## (docs/ROADMAP.md Phase 8) — it has no pacing, intensity, or scheduling
## logic, it just answers "something happened, who's free and closest?"
## immediately, every time. Police units decide everything about HOW they
## respond themselves (scripts/ai/police/police_ai.gd); this only decides WHO.
##
## Keeps HeroAI and PoliceAI fully decoupled — Hero only ever emits
## WorldEvents (docs/ROADMAP.md Phase 6 architecture requirement).
extends Node

## Last vehicle reported stolen — used so a dispatched unit has something
## concrete to pursue, not just the position a crime happened to occur at.
var _last_stolen_vehicle: Node = null


func _ready() -> void:
	WorldEvents.vehicle_stolen.connect(_on_vehicle_stolen)
	WorldEvents.danger_created.connect(_on_danger_created)


func _on_vehicle_stolen(vehicle: Node, position: Vector3) -> void:
	_last_stolen_vehicle = vehicle
	_dispatch(position, vehicle)


func _on_danger_created(position: Vector3, _radius: float) -> void:
	_dispatch(position, _last_stolen_vehicle)


func _dispatch(position: Vector3, vehicle: Node) -> void:
	var unit := _find_nearest_available_unit(position)
	if unit != null:
		unit.dispatch_to(position, vehicle)


func _find_nearest_available_unit(position: Vector3) -> Node:
	var nearest: Node = null
	var nearest_dist := INF
	for unit in get_tree().get_nodes_in_group("police"):
		if not unit.is_available():
			continue
		var d: float = unit.global_position.distance_to(position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = unit
	return nearest
