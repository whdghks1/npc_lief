## Detects nearby Interactable components and lets the player trigger them.
##
## Lives on an Area3D child of the player so the detection range/shape stays
## data-driven (resize the CollisionShape3D instead of touching code). Its
## collision_mask should only include the "interactable" physics layer
## (layer 3) so it never reacts to plain scenery.
class_name Interactor
extends Area3D

signal target_changed(interactable: Interactable)

var current_target: Interactable = null

var _candidates: Array[Interactable] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func try_interact(by: Node) -> void:
	if current_target != null:
		current_target.interact(by)


func _on_body_entered(body: Node3D) -> void:
	var interactable := _find_interactable(body)
	if interactable == null:
		return
	_candidates.append(interactable)
	_update_target()


func _on_body_exited(body: Node3D) -> void:
	var interactable := _find_interactable(body)
	if interactable == null:
		return
	_candidates.erase(interactable)
	_update_target()


func _find_interactable(body: Node3D) -> Interactable:
	for child in body.get_children():
		if child is Interactable:
			return child
	return null


func _update_target() -> void:
	var new_target: Interactable = null
	if not _candidates.is_empty():
		new_target = _candidates[-1]
	if new_target != current_target:
		current_target = new_target
		target_changed.emit(current_target)
