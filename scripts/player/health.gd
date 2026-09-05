## Generic health component.
##
## Phase 7 connects this to actual hazards (vehicle impacts, via
## scripts/systems/vehicle_impact.gd) — before that it just existed for the
## HUD to display.
class_name Health
extends Node

signal health_changed(current: float, max_health: float)
## `cause` is whatever was last passed to take_damage() — a short, readable
## string for the Life Report ("Hit by a stolen vehicle during a police
## pursuit"), not a forensic system.
signal died(cause: String)

@export var max_health: float = 100.0

var current_health: float = max_health
var last_damage_cause: String = ""


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: float, cause: String = "") -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return
	if not cause.is_empty():
		last_damage_cause = cause
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit(last_damage_cause)


func heal(amount: float) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
