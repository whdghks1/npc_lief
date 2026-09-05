## Generic health component.
##
## Not wired to any damage source yet — no hazards exist before later
## roadmap phases (Phase 7 "NPC Survival"). Phase 1 only needs the stat to
## exist and be readable by the HUD.
class_name Health
extends Node

signal health_changed(current: float, max_health: float)
signal died

@export var max_health: float = 100.0

var current_health: float = max_health


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: float) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
