## Generic "this can be interacted with" component.
##
## Attach as a child of any physical body that has a collision shape on the
## interactable physics layer (layer 3, see scripts/player/interactor.gd).
## This node only knows how to *be* interacted with — it has no idea who is
## interacting with it or what should happen; concrete objects listen to
## `interacted` and react (see scripts/core/test_interactable.gd).
class_name Interactable
extends Node

signal interacted(by: Node)

## Shown by the HUD as "[E] <prompt>" when this is the player's current target.
@export var prompt: String = "Interact"


func interact(by: Node) -> void:
	interacted.emit(by)
