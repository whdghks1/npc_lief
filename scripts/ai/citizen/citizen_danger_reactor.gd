## Bridges WorldEvents to Citizen's existing reaction API (autoload
## "CitizenDangerReactor").
##
## Split out from HeroAI so nothing that CAUSES danger — Hero today, anyone
## else later — needs to know citizens exist at all. It only emits
## WorldEvents.danger_created; this is the one thing that turns that into
## actual citizen behavior. Deliberately tiny: find nearby citizens, call
## the reaction methods they already have.
extends Node


func _ready() -> void:
	WorldEvents.danger_created.connect(_on_danger_created)


func _on_danger_created(position: Vector3, radius: float) -> void:
	for citizen in get_tree().get_nodes_in_group("citizens"):
		if citizen.global_position.distance_to(position) <= radius:
			citizen.react_to_danger(position)
